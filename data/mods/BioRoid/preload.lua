BioRoid = {}
BioRoid.player_act_counter = nil
BioRoid.callback = nil
BioRoid.ignore_enemy = false
BioRoid.item = nil
BioRoid.properties = {}

function BioRoid.convert_creature_to_npc(creature)
    local npc
    if creature then
        if creature:is_npc() then
            npc = debug.setmetatable(creature, debug.getmetatable(player))
            return npc
        end
    end
    return nil
end

function BioRoid.get_corpse(p)
    for delta_x = -1, 1 do
        for delta_y = -1, 1 do
            local tpoint = tripoint(p.x + delta_x, p.y + delta_y, p.z)
            local stack = map:i_at(tpoint)
            local iter = stack:cppbegin()
            while iter ~= stack:cppend() and not corpse do
                local tmp = iter:elem()
                if tmp:is_corpse() then
                    if tmp:get_mtype():get_meat_itype() == "human_flesh" then
                        return tmp, tpoint
                    end
                end
                iter:inc()
            end
        end
    end
    return nil, nil
end

function BioRoid.iuse_bioroid_kit(item, active)
    local p = player:pos()
    local delta_x
    local delta_y
    local corpse, tpoint = BioRoid.get_corpse(p)
    if corpse == nil then
        game.add_msg("주위에 시체가 없습니다! 개조하려는 시체를 바닥에 두세요.")
        return
    end
    
    BioRoid.properties["gender"] = item:get_property_string("gender")
    BioRoid.properties["bioroid_type"] = item:get_property_string("type")
    -- 나중에 아이템을 지우는 용
    BioRoid.properties["typeid"] = item:typeId() -- item이 이 함수 내에서만 쓸 수 없기에, itype의 카피를 통해서
    BioRoid.properties["corpse"] = corpse
    BioRoid.properties["corpse_tpoint"] = tpoint
    BioRoid.ignore_enemy = false
    --
    -- 작업 시간(30분)
    BioRoid.player_act_counter = 300
    BioRoid.callback = BioRoid.working
    player:set_moves(-1000)
end

function BioRoid.working()
    local p = player:pos()
    local bioroid_type = BioRoid.properties["bioroid_type"]
    local template = npc_template_id(bioroid_type)
    local npc_tpoint = nil
    if BioRoid.player_act_counter % 100 == 0 then
        game.add_msg("작업을 하는 중이다...")
    end
    -- 턴 마다, 나머지 공정을 1씩 감소
    BioRoid.player_act_counter = BioRoid.player_act_counter - 1

    -- 적이 가까이 오면 경고 개시
    local crit = g:is_hostile_nearby()
    if crit and not BioRoid.ignore_enemy then
        local msg = crit:disp_name() .. "가(이) 가까이 있습니다. 작업을 취소하시겠습니까?"
        if game.query_yn(msg) then
            BioRoid.callback = nil
            player:set_moves(0)
            return
        else
            BioRoid.ignore_enemy = true
        end
    end
    crit = g:is_hostile_very_close()
    if crit then
        local msg = crit:disp_name() .. "가(이) 바로 옆에 있다! 작업을 취소하시겠습니까?"
        if game.query_yn(msg) then
            BioRoid.callback = nil
            player:set_moves(0)
            return
        end
    end

    -- 작업 완료시
    if BioRoid.player_act_counter <= 0 then
        for delta_x = -1, 1 do
            for delta_y = -1, 1 do
                local tpoint = tripoint(p.x + delta_x, p.y + delta_y, p.z)
                if not g:critter_at(tpoint) then
                    npc_tpoint = tpoint
                end
            end
        end
        if not npc_tpoint then
            game.add_msg("생체 안드로이드를 둘 장소가 없다!")
            -- 실패시, 콜백을 삭제한다.
            BioRoid.callback = nil
            player:set_moves(0)
            return
        end
        map:place_npc(npc_tpoint.x, npc_tpoint.y, template)
        -- place_npc 뒤, 시간이 경과하지 않으면 NPC가 나타나지 않는 문제때문에 on_turn_passed에 콜백을 건다.
        BioRoid.callback = BioRoid.finished
        BioRoid.player_act_counter = 50 -- 50턴이 지나도, NPC가 안보이면 실패
    end
    player:set_moves(-1000)
end

function BioRoid.finished()
    local p = player:pos()
    local npc = nil
    local delta_x
    local delta_y
    local item = BioRoid.gen_bioroid_item
    local gender = BioRoid.properties["gender"]
    local found = false
    BioRoid.player_act_counter = BioRoid.player_act_counter - 1
    if BioRoid.player_act_counter <= 0 then
        game.add_msg("오류! NPC 생성에 실패했습니다!")
        -- 실패시, 콜백을 삭제한다.
        BioRoid.callback = nil
        player:set_moves(0)
        return
    end
    for delta_x = -20, 20 do
        for delta_y = -20, 20 do
            local tpoint = tripoint(p.x + delta_x, p.y + delta_y, p.z)
            npc = BioRoid.convert_creature_to_npc(g:critter_at(tpoint))
            -- 생성된 생체 안드로이드가 있는 지 확인
            if npc then
                if npc:has_trait(trait_id("BIOROID_BASE")) 
                   and npc:get_value("bioroid_init") ~= "init" then
                    found = true
                end
            end
            if found then
                break
            end
        end
        if found then
            break
        end
    end
    if npc then
        -- 데이터 초기화
        if gender == "male" then
            npc.male = true
        elseif gender == "female" then
            npc.male = false
        end
        newname = game.string_input_popup("이름을 입력하십시오", 30, "")
        if newname ~= "" then
            npc.name = newname
        end
        npc:set_value("bioroid_init", "init")
        -- 처리가 끝나면 콜백 삭제
        player:set_moves(0)
        BioRoid.callback = nil
        -- 아이템을 소모
        local removed = false
        local i = -1
        while not player:i_at(i):is_null() and not removed do
            local tmp = player:i_at(i)
            if tmp:typeId() == BioRoid.properties["typeid"] then
                player:i_rem(i)
                removed = true
            end
            i = i - 1
        end
        i = 0
        while not player:i_at(i):is_null() and not removed do
            local tmp = player:i_at(i)
            if tmp:typeId() == BioRoid.properties["typeid"] then
                player:i_rem(i)
                removed = true
            end
            i = i + 1
        end
        -- 死体を消費
        map:i_rem(BioRoid.properties["corpse_tpoint"], BioRoid.properties["corpse"])
        game.add_msg("생체 안드로이드가 움직이기 시작했다！")
        return
    end
    player:set_moves(-1000)
end

game.register_iuse("IUSE_BIOROID_KIT", BioRoid.iuse_bioroid_kit)

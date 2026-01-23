--[[
	MB_ACT_FLG		메이드 씨(쇼고스) 용
		Num ModeName	Active	Desc
		0:일반 모드	보통	지시를 내리지 않은 초기 상태
		1:소극적 모드	소극적	소극적으로, 따라는 오지만 조금 불안정
		2:조명 모드	소극적	조명 모드, 빛나는 소극적 모드. 속도 0인 상태로 움직임이 정지한 상태

	MB_ACT_FLG_L	리틀 메이드 용
		Num ModeName	Active	Desc
		0:일반 모드	보통	지시를 내리지 않은 초기 상태
		1:소극적 모드	소극적	소극적으로, 따라는 오지만 조금 불안정
--]]

function iuse_maid_bell(item, active)
	if active then
		local unlimit_list = serch_arround(3, "shoggoth")
		
		if #unlimit_list == 0 then
			item.active = false
			local mtype = mtype_id("mon_shoggoth_maid"):obj()
	
			mtype.armor_bash = mtype.armor_bash / 4
			mtype.armor_cut = mtype.armor_cut / 4
			mtype.melee_dice = mtype.melee_dice / 4
			mtype.melee_sides = mtype.melee_sides / 4
			mtype.melee_skill = mtype.melee_skill / 2
			return
		end
		
		local unlimit_maid = unlimit_list[1]
		
		local dist = game.distance(player:posx(), player:posy(), unlimit_maid:posx(), unlimit_maid:posy())
		
		if dist > 8 then
			local p_list = get_arround_point(1)
			unlimit_maid:setpos(p_list[1])
		end

		local unlimit_flg = unlimit_maid:has_effect(efftype_id("MB_UNLIMIT"))

		if not unlimit_flg then
			item.active = false
			remove_unlimit()
		end

	else
		local maid_list = serch_arround(1, "shoggoth")
		
		if #maid_list == 0 then
			local salvation = salvation_maid()
			
			if salvation then
				return
			else
				game.add_msg("주변에 메이드 씨가 없는 것 같다.")
			end
			return
			--追加 付近(ベル有効範囲)にショゴスメイドさんが一人だけの場合にのみベルによるコントロールを有効に
		elseif #maid_list > 1 then
			game.add_msg("주변에 메이드 씨가 너무 많은 것 같다.")
			return
		end
		
		for i = 1, #maid_list do
		local maid = maid_list[i]
		if maid:has_effect(efftype_id("MB_UNLIMIT")) then
			game.add_msg("메이드 씨는 머리 부분에 피가 쏠려서 말이 들리지 않는 것 같다.")
			player:mod_moves(-100)
			return
		end
	end

--uimenu생성
		local menu = game.create_uimenu()
		local choice = -1
		
		local title_string = "어떤 일인가요, 주인님!"

		local name_string = maid_list[1].unique_name

		if #name_string ~= 0 and game.one_in(2) then
			title_string = string.format("주인님의 %s랍니다~!",name_string)
		end

		menu.title = "\"네~ 넷~ 무슨 용무신가요? 주인님!\""
		menu:addentry("아무것도 아니야")										--choice 0
		menu:addentry("평소처럼 해줘  (일반 모드)")						--choice 1
		menu:addentry("응원하고 있어줘 (소극적 모드)")						--choice 2
		menu:addentry("조명이 필요해  (발광 모드)")						--choice 3
		menu:addentry("가까이 와줘   (근처로 순간 이동/Maid Point 소모)")	--choice 4
		menu:addentry("지금 상태를 말해줘 (현재 모드 표시)")				--choice 5
--추가
		menu:addentry("*이름*을 붙인다  (메이드 씨에게 이름을 붙입니다)")			--choice 6
		menu:addentry("작아져줘          (메이드 씨가 아이템화됩니다)")				--choice 7
--추가 여기까지
	
		if check_unlimit(maid_list) then
			menu:addentry("도와줘!! (메이드 씨가 진심을 냅니다)")	--choice 8
		end

		menu:query(true)
		choice = menu.selected

--메뉴 선택에 따른 분기
		if choice == 0 then
			select_nothing()
			return
		elseif choice == 1 then
			maid_normalize(maid_list, "shoggoth")
			select_normal(maid_list)
			player:mod_moves(-100)
			return
		elseif choice == 2 then
			maid_normalize(maid_list, "shoggoth")
			select_passive(maid_list)
			player:mod_moves(-100)
			return
		elseif choice == 3 then
			maid_normalize(maid_list, "shoggoth")
			select_lighting(maid_list)
			player:mod_moves(-100)
			return
		elseif choice == 4 then
			select_summon_near(maid_list)
			player:mod_moves(-100)
			return
		elseif choice == 5 then
			select_modedisp()
			player:mod_moves(-50)
			return
		elseif choice == 6 then
			rename_maid(maid_list)
			player:mod_moves(-50)
			return
		elseif choice == 7 then
			maid_revert_to_item(maid_list)
			return
		elseif choice == 8 then
			select_unlimit(maid_list)
			player:mod_moves(-100)
			item.active = true
		end
	end
end

function iuse_little_bell(item, active)
	local maid_list = serch_arround(1, "little")
	
	if #maid_list == 0 then
		game.add_msg("근처에 리틀 메이드가 없는 것 같다.")
		return
	end
	
--uimenu생성
	local menu = game.create_uimenu()
	local choice = -1

	menu.title = "\"주인님?\""
	menu:addentry("아무것도 아니야")										--choice 0
	menu:addentry("마음대로 움직여도 돼  (일반 모드)")						--choice 1
	menu:addentry("잠깐 얌전하게 있어줘  (소극적 모드)")						--choice 2
	menu:addentry("지금 상태는 어때?   (현재 모드 표시)")				--choice 3

	menu:query(true)
	choice = menu.selected

	if choice == 0 then
		select_nothing_little()
		return
	elseif choice == 1 then
		maid_normalize(maid_list, "little")
		select_normal_little(maid_list)
		return
	elseif choice == 2 then
		maid_normalize(maid_list, "little")
		select_passive_little(maid_list)
		return
	elseif choice == 3 then
		select_modedisp_little()
		return
	end
end

function iuse_little_cake(item, active)
	local t_x, t_y = game.choose_adjacent("누구에게?", player:pos().x, player:pos().y)
	local target = tripoint(t_x, t_y, player:pos().z)
	local crit = g:critter_at(target)
	
	if not crit then
		game.add_msg("거기에는 아무도 없다.")
		return
	end
	
	if crit:is_player() then
		game.add_msg("스스로 먹을거니?")
		return
	end
	
	if not crit:is_monster() then
		game.add_msg("부드럽게 거부됬다...")
		return
	end
	
	local mob = game.get_monster_at(target)
	local use_flg = false
	
	if mob.type.id == mtype_id("mon_shoggoth_maid") then
		game.popup("<color_yellow>\"나에게 선물...인가요?\"</color>")
		local select = game.query_yn("정말 주겠습니까?")

		if select then
			game.popup("<color_yellow>\"음~ 의욕이 나고있어요~!\"</color>")
			game.add_msg("메이드 씨의 호감도가 증가했다!")
			game.add_msg("그러나 호감도는 이미 최대치에 달했다.")
			use_flg = true
		else
			game.popup("<color_yellow>\"심술궂네요! 아니면 츤데레인가요!?\"</color>")
			game.popup("<color_yellow>\"나는 어느쪽도 환영이에요!!\"</color>")
		end
	elseif mob.type.id == mtype_id("mon_little_maid") then
		game.popup("<color_yellow>눈을 빛내며 이쪽을 올려다보고 있다.</color>")
		local select = game.query_yn("정말 주겠습니까?")
		
		if select then
			game.popup("<color_yellow>메이드 씨는 케이크를 받고 크게 흥분했다!</color>")
			game.add_msg("메이드 씨의 사기가 올랐다!")
			game.add_msg("조금 더 빠르게 움직인다!")
			mob:add_effect(efftype_id("MB_LITTLE_FUN"), TURNS(300))
			use_flg = true
		else
			game.popup("<color_yellow>메이드 씨는 울듯한 표정을 하고 있다...</color>")
			game.popup("<color_yellow>아, 조금 울어버렸다...</color>")
			game.add_msg("메이드 씨의 신뢰도가 떨어진 것 같다.")
		end
	elseif mob.type.id == mtype_id("mon_lone_little_maid") then
		game.popup("<color_yellow>경계는 하고 있지만 기대에 찬 눈으로 이쪽을 올려다보고 있다...</color>")
		local select = game.query_yn("정말 주겠습니까?")

		if select then
			game.popup("<color_yellow>메이드 씨에게 케이크를 줬다.</color>")
			game.popup("<color_yellow>메이드 씨는 매우 기뻐하고 있는 것 같다.</color>")
			game.popup("<color_yellow>아무래도 답례? 로 이쪽으로 넘어올 것 같다.</color>")
			game.popup("메이드 씨가 동료? 가 됬다!")
			mob:poly(mtype_id("mon_little_maid"))
			mob.friendly = -1
			use_flg = true
		else
			game.popup("<color_yellow>메이드 씨는 실망하고 있다...</color>")
		end
	else
		game.add_msg("...줄 수 있는 상대가 아닌 것 같다.")
	end
	
	if use_flg then
		player:i_rem(item)
	end
end

--[[
	周囲1マスの空きスペースを探査・取得・ランダム選定
	アイテムから名前を取得
	メイドさん召喚
	メイドさんのユニーク名にセット
	アイテムテイクオフ
	アイテム消去
--]]
function iuse_loved_maid(item, active)
	local nearby = get_arround_point(6)
	local maid_name = item:get_var("MB_MAID_NAME", "null")
	
	local maid = game.create_monster(mtype_id("mon_shoggoth_maid"), nearby[game.rng(1, #nearby)])
	maid.friendly = -1
	if maid_name ~= "null" then
		maid.unique_name = maid_name
	else
		game.add_msg("maid name missing!!")
	end
	game.add_msg("<color_yellow>「기다리게 했나요, 주인님! 앞으로도 일상,가사 지원부터 마음과 몸의 케어까지 성심성의껏 모시겠으니 잘 부탁드려요-♪」</color>")
	
	player:i_rem(item)
end

function check_unlimit(list)
--이미 판명된 테이블에 여러 메이드가 있을 경우, False 반환
	if #list > 1 then
		return false
	end
	
--범위 60 내 쇼거스 메이드 씨 탐색
	local maid_list = serch_arround(2, "shoggoth")

--범위 내, 메이드 씨가 둘 이상일 경우 False 반환
	if #maid_list > 1 then
		return false
	end

--기술적 간략화를 위해 테이블 단일 변수로
	local maid = maid_list[1]

--메이드 씨와 거리가 8(메이드 씨의 시야)보다 멀 경우 False 반환
	if game.distance(player:posx(), player:posy(), maid:posx(), maid:posy()) > 8 then
		return false
	end
	
--떠돌이 메이드를 한 번이라도 도와준 적이 있는가 = 구원 특성을 이미 획득했는지 여부
	local slv_flg = not player:has_trait(trait_id("MB_TRAIT_SALVATION"))


--메이드 씨, 남은 HP 90% 미만일 경우 False 반환
	if maid:hp_percentage() < 90 and slv_flg then
		return false
	end

--플레이어의 사지(양 팔 다리)가 모두 정상인 지, 체크
--	모두 정상이면 :ture, 하나라도 결손됐으면 :false
	local part_flg = true
	for i = 3, 6 do
		if player:get_hp(enums["hp_part"][i]) <= 0 then
			part_flg = false
		end
	end

--플레이어 남은 HP 76% 이상이면 사지가 멀쩡할 때 False 변환
	if player:hp_percentage() > 75 and part_flg and slv_flg then
		return false
	end

--인터벌 종료 예정 턴과 현재 턴 취득
	local cooldown_flg = maid:has_effect(efftype_id("MB_COOLDOWN"))

	if cooldown_flg then
		return false
	end
	
	return true
end

function serch_arround(type, target)
	local maid_list = {}
	local range = 30

--[[
	type
		1:일반 탐색 모드range = 30
		2:확대 탐색 모드range = 60
		3:강화 탐색 모드range = 60,get_value("MB_UNLIMIT_FLG") == 1의 탐색
		“4: 떠돌이 메이드 전용 모드, 범위 = 5”
--]]
	if type >= 2 and type <= 3 then
		range = 60
	elseif type == 4 then
		range = 5
	end
--주변( 플레이어 반경 range 범위)에 메이드 씨(쇼거스)나 리틀 메이드 개체를 찾는 탐색
	for x_i = -1*range, range do
		for y_i = -1*range, range do
			local point = player:pos()
			point.x = point.x + x_i
			point.y = point.y + y_i
			local crit = g:critter_at(point)
			if crit then												--지정 좌표에 뭔가 있다.
				if crit:is_monster() then								--그것이 몬스터
					local mob = game.get_monster_at(point)
					if mob.type.id == mtype_id("mon_shoggoth_maid") and	--쇼거스 메이드 씨
						target == "shoggoth" then						--찾는 대상이 쇼거스 메이드 씨고
						if type <= 2 then								--일반 탐색 모드면
							table.insert(maid_list, mob)				--리스트에 추가한다.
						else
							local limit_flg = mob:has_effect(efftype_id("MB_COOLDOWN"))
							if limit_flg then
								table.insert(maid_list, mob)
								return maid_list
							end
						end
					elseif mob.type.id == mtype_id("mon_little_maid") and	--마찬가지로 리틀 메이드
						target == "little" then							--찾는 대상이 리틀 메이드면
						table.insert(maid_list, mob)					--리스트에 추가한다.
					elseif mob.type.id == mtype_id("mon_lone_shoggoth_maid") and
						target == "lone_maid" then
						if player:sees(mob) then
							table.insert(maid_list, mob)
							return maid_list
						end
					end
				end
			end
		end
	end

	return maid_list
end

function select_nothing()
	local msg_sw = game.rng(0, 3)
	if msg_sw == 0 then
		game.add_msg("<color_yellow>\"불러봤을 뿐♪ 이란 거네요\"</color>")
	elseif msg_sw == 1 then
		game.add_msg("<color_yellow>\"우후후후～♪</color>")
		game.add_msg("<color_yellow> 더 불러주셔도 괜찮다고요?\"</color>")
	elseif msg_sw == 2 then
		game.add_msg("<color_yellow>\"우후훗～♪</color>")
		game.add_msg("<color_yellow> 제가 걱정되신 건가요？</color>")
		game.add_msg("<color_yellow> 괜찮아요!! 튼튼하니까요！\"</color>")
	elseif msg_sw == 3 then
		game.add_msg("<color_yellow>\"우우우, 방치 플레이인가요?</color>")
		game.add_msg("<color_yellow> 이것도 나름대로... 좋네요！\"</color>")
	end
end

function select_nothing_little()
	local msg_sw = game.rng(0, 3)
	if msg_sw == 0 then
		game.add_msg("<color_yellow>이 쪽을 보고 미소를 짓고 있다.</color>")
	elseif msg_sw == 1 then
		game.add_msg("<color_yellow>마음대로 근처를 배회하고 있다.</color>")
	elseif msg_sw == 2 then
		game.add_msg("<color_yellow>그 자리에서 빙글 돌더니, 인사를 해왔다.</color>")
	elseif msg_sw == 3 then
		game.add_msg("<color_yellow>열심히 하겠습니다! 란 마음이 담긴 얼굴을 하고 있다.</color>")
	end
end

function select_normal(maid_list)
	game.add_msg("<color_yellow>\"받들겠습니다</color>")
	game.add_msg("<color_yellow> 자! 열심히 쓰러뜨렸다고요♪\"</color>")

	player:set_value("MB_ACT_FLG", "0")
end

function select_normal_little(maid_list)
	game.add_msg("<color_yellow>두 주먹을 쥐고 기합을 넣고 있다.</color>")

	player:set_value("MB_ACT_FLG_L", "0")
end

function select_passive(maid_list)
	game.add_msg("<color_yellow>\"받들겠습니다</color>")
	game.add_msg("<color_yellow> 위험해지면 바로 불러주세요?\"</color>")

	for i = 1, #maid_list do
		local maid = maid_list[i]

		maid:add_effect(efftype_id("docile"), game.get_time_duration(1), "num_bp", true)
	end

	player:set_value("MB_ACT_FLG", "1")
end

function select_passive_little(maid_list)
	game.add_msg("<color_yellow>뒤 쪽에서 걱정스러운 눈으로 바라보고 있다.</color>")

	for i = 1, #maid_list do
		local maid = maid_list[i]

		maid:add_effect(efftype_id("docile"), game.get_time_duration(1), "num_bp", true)
	end

	player:set_value("MB_ACT_FLG_L", "1")
end

function select_lighting(maid_list)
	game.add_msg("<color_yellow>\"받들겠습니다</color>")
	game.add_msg("<color_yellow> 으으으으으읏～</color>")
	game.add_msg("<color_yellow> 어떤가요? 밝아졌나요?\"</color>")

	local maid_type = mtype_id("mon_shoggoth_maid"):obj()
	
	maid_type.luminance = 50

	for i = 1, #maid_list do
		local maid = maid_list[i]

		maid:set_speed_base(0)
		maid:add_effect(efftype_id("docile"), game.get_time_duration(1), "num_bp", true)
	end

	player:set_value("MB_ACT_FLG", "2")
end

function select_summon_near(maid_list)
	local need_power = 0
	
	for i = 1, #maid_list do
		local maid = maid_list[i]
		if player:has_trait(trait_id("MB_TRAIT_SALVATION")) then
			need_power = need_power + math.floor( game.distance(player:posx(), player:posy(), maid:posx(), maid:posy()) / 2 )
		else
			need_power = need_power + game.distance(player:posx(), player:posy(), maid:posx(), maid:posy())
		end
	end

	if not player:has_charges("maid_point", need_power) then
		game.add_msg("<color_yellow>\"으으읏...</color>")
		game.add_msg("<color_yellow> 주인님!</color><color_cyan>Maid Point</color><color_yellow>가 부족합니다!\"</color>")
		return
	end
	
	local point_list = get_arround_point(#maid_list)
	
	local idx = 0
	local mp_item = nil
	while true do
		local tmp_i = player:i_at(idx)
		if tmp_i:typeId() == "maid_point" then
			mp_item = tmp_i
			break
		end
		idx = idx + 1
	end
	
	mp_item.charges = mp_item.charges - need_power + #maid_list
	
	for i = 1, #maid_list do
		local maid = maid_list[i]
		maid:setpos(point_list[i])
		
		game.add_msg("<color_yellow>\"불려 나왔습니다～♪</color>")
		game.add_msg("<color_yellow> 지금 등장했습니다! 주인님！\"</color>")
	end
end

function get_arround_point(num)
	point_list = {}
	idx = -1

	while true do
		for xi = idx, math.abs(idx) do
			for yi = idx, math.abs(idx) do
				local point = tripoint(player:posx() + xi, player:posy() + yi, player:posz())
				if math.abs(xi) > math.abs(idx + 1) or math.abs(yi) > math.abs(idx + 1) then
					if g:is_empty(point) then
						table.insert(point_list, point)
						if #point_list >= num then
							return point_list
						end
					end
				end
			end
		end
		idx = idx - 1
	end
end

function select_modedisp()
	local type = tonumber(player:get_value("MB_ACT_FLG")) or 0
	if type == 0 then
		game.add_msg("<color_yellow>\"지금은</color><color_cyan>일반 모드</color><color_yellow>랍니다！</color>")
		game.add_msg("<color_yellow> 좀비 따위는 손 쉽게 쓰러뜨릴게요～♪\"</color>")
	elseif type == 1 then
		game.add_msg("<color_yellow>\"지금은</color><color_cyan>응원 모드</color><color_yellow>랍니다！</color>")
		game.add_msg("<color_yellow> 주인님 힘내라♪ 힘♪ 힘내라♪\"</color>")
	elseif type == 2 then
		game.add_msg("<color_yellow>\"지금은</color><color_cyan>조명 모드</color><color_yellow>랍니다！</color>")
		game.add_msg("<color_yellow> 우후후～ 빛나는 저도 귀엽지 않나요？</color>")
		game.add_msg("<color_yellow> 귀엽지 않나요~♪\"</color>")
	end
end

function select_modedisp_little()
	local type = tonumber(player:get_value("MB_ACT_FLG_L")) or 0
	if type == 0 then
		game.add_msg("<color_yellow>리틀 메이드는 자기 마음대로 움직이고 있다.</color>")
		game.add_msg("<color_cyan>평소대로 </color><color_yellow>싸워줄테지</color>")
	elseif type == 1 then
		game.add_msg("<color_yellow>리틀 메이드가 숨으면서 따라오고 있다.</color>")
		game.add_msg("<color_cyan>소극적으로</color><color_yellow>행동하고 있는 것 같다.</color>")
	end
end

function rename_maid(maid_list)
	local maid = maid_list[1]
	local name_string = ""
	
	if #maid.unique_name ~= 0 then
		name_string = maid.unique_name
		local rename_select = game.query_yn(string.format("이미 「%s」(이)라고 부르고 있어요.\n다시 이름을 정할까요?", name_string))
		if not rename_select then
			return
		end
	end

	local repeater = true
	
	while repeater do
		name_string = game.string_input_popup("", 20, "메이드 씨를 뭐라고 부를까요?")
		if name_string == "" then
			local cancel_rename = game.query_yn("이름 붙이기를 그만둘까요?")
			if cancel_rename then
				return
			end
		else
			if game.query_yn(string.format("메이드 씨를 %s(이)라고 부르기로 합니다.\n이대로 좋나요?", name_string)) then
				repeater = false
			end
		end
	end
	
	game.add_msg(string.format("<color_yellow>\"</color><color_cyan>%s</color><color_yellow>...인가요?</color>", name_string))
	game.add_msg(string.format("<color_yellow> 에헤헤~♪ 우후후~♪\n 앞으로도 잘 부탁드려요!\"</color>"))
	
	maid.unique_name = name_string
end

function maid_revert_to_item(maid_list)
	local maid = maid_list[1]
	local hp_perc = maid:hp_percentage()
	local maid_name = maid.unique_name
	local maid_place = tripoint( maid:pos().x, maid:pos().y, maid:pos().z )
	
	if hp_perc < 100 then
		if not game.query_yn("메이드 씨의 몸 상태가 완전하지 않아서, 이대로 두면\n<color_red>작은 메이드 씨(쇼고스)</color>가 되어버립니다.\n그래도 괜찮으신가요?") then
			return
		end
	end
	
	if hp_perc == 100 then
		if maid_name ~= "" then
			game.add_item_to_group("shoggoth_maid_drop", "mini_shoggoth", 0)
			game.add_item_to_group("shoggoth_maid_drop", "loved_shoggoth", 100)
		else
			game.add_item_to_group("shoggoth_maid_drop", "mini_shoggoth", 0)
			game.add_item_to_group("shoggoth_maid_drop", "res_shoggoth", 100)
		end
	end
	
	maid_normalize(maid_list, "shoggoth")
	
	maid:die(maid)

	if hp_perc == 100 then
		if maid_name ~= "" then
			game.add_item_to_group("shoggoth_maid_drop", "mini_shoggoth", 100)
			game.add_item_to_group("shoggoth_maid_drop", "loved_shoggoth", 0)
		else
			game.add_item_to_group("shoggoth_maid_drop", "mini_shoggoth", 100)
			game.add_item_to_group("shoggoth_maid_drop", "res_shoggoth", 0)
		end
	end
	
	if maid_name ~= "" then
		local loved = serch_loved_maid(maid_place)
		if not loved then
			game.add_msg("메이드 씨가 행방불명?")
			game.add_msg("에러입니다! 즉시 관리자(아마에마님)에게 문의해 주세요.")
			return
		end
		
		loved:set_var("MB_MAID_NAME", tostring(maid_name))
	end
	
	game.add_msg(string.format("<color_yellow>\"주인님~! 꼭 주워주세요~!?\"</color>"))
end

function serch_loved_maid(point)
	local stack = map:i_at(point)
	local iter = stack:cppbegin()
	
	while iter ~= stack:cppend() do
		local tmp = iter:elem()
		if tmp:typeId() == "loved_shoggoth" then
			return tmp
		end
		iter:inc()
	end
	
	return nil
end

function select_unlimit(maid_list)
	game.add_msg("<color_dark_gray_red>\"주인님께 손을 대다니 괘씸한 것...</color>")
	game.add_msg("<color_dark_gray_red> 모조리 죽어 마땅하겠구나...죽어, 전부！！</color>")
	game.add_msg("<color_dark_gray_red> 테켈리-리！！테켈리-리！！\"</color>")

	local maid = maid_list[1]
	local mtype = mtype_id("mon_shoggoth_maid"):obj()

--강화 전, 한 번 정상(일반 모드)로 변경
	maid_normalize(maid_list, "shoggoth")

--메이드 씨 강화(강화)
	mtype.armor_bash = mtype.armor_bash * 6
	mtype.armor_cut = mtype.armor_cut * 6
	mtype.armor_stab = mtype.armor_stab * 2
	mtype.melee_dice = mtype.melee_dice * 6
	mtype.melee_sides = mtype.melee_sides * 5
	mtype.melee_skill = mtype.melee_skill * 3
	maid:set_speed_base(2000)

--진심 모드 종료 턴 설정
	maid:add_effect(efftype_id("MB_UNLIMIT"), game.get_time_duration(30))
	maid:add_effect(efftype_id("MB_COOLDOWN"), game.get_time_duration(330))
end

function remove_unlimit()
	game.add_msg("<color_yellow>\"...후우</color>")
	game.add_msg("<color_yellow> 주인님！괜찮으신가요？\"</color>")

	local maid_list = serch_arround(3, "shoggoth")
	local maid = maid_list[1]
	local mtype = mtype_id("mon_shoggoth_maid"):obj()
	
	mtype.armor_bash = mtype.armor_bash / 6
	mtype.armor_cut = mtype.armor_cut / 6
	mtype.armor_stab = mtype.armor_stab / 2
	mtype.melee_dice = mtype.melee_dice / 6
	mtype.melee_sides = mtype.melee_sides / 5
	mtype.melee_skill = mtype.melee_skill / 3
	maid:set_speed_base(200)
end

function maid_normalize(maid_list, target)
	local maid_type = nil
	
	if target == "shoggoth" then
		maid_type = mtype_id("mon_shoggoth_maid"):obj()
	elseif target == "little" then
		maid_type = mtype_id("mon_little_maid"):obj()
	end
	
	maid_type.luminance = 0

	for i = 1, #maid_list do
		local maid = maid_list[i]

		maid:set_speed_base(200)
		maid:remove_effect(efftype_id("docile"), "num_bp")
	end
end

function salvation_maid()
	local maid_list = serch_arround(4, "lone_maid")
	
	if #maid_list == 0 then
		return false
	end
	
	local guilt_count = g:kill_count(mtype_id("mon_lone_shoggoth_maid"))
	local salv_count = tonumber(player:get_value("MB_SALV_COUNT")) or 0
	
	player:mod_moves(-100)
	
	game.popup("떠도는 메이드 씨에게 들리도록 벨을 울렸다...")

	if game.one_in(2 + math.max( ( guilt_count - salv_count ), 0 )) then

		if not player:has_trait(trait_id("MB_TRAIT_SALVATION")) then
		
	game.popup("<color_red>\"아아...아아...\"</color>")
	game.popup("<color_red>\"주인님...그곳에 계셨군요...\"</color>")
	game.popup("<color_red>\"지금, 곁에</color><color_yellow>있습니다♪\"</color>")
	game.popup("<color_yellow>\"이제...다시는 놓치지 않으니까요...!\"</color>")
	game.popup("<color_yellow>\"고맙습니다, 이름모를 주인님♪\"</color>")
	
			player:set_mutation(trait_id("MB_TRAIT_SALVATION"))
		else
			game.popup("떠도는 메이드 씨는 만족스러운 표정을 짓고 그 자리에 푹 쓰러졌다...")
		end
	local maid = maid_list[1]
	
	game.add_item_to_group("lone_shoggoth_maid_drop", "broken_master_doll", 0)
	game.add_item_to_group("lone_shoggoth_maid_drop", "broken_maid_dress", 0)
	game.add_item_to_group("lone_shoggoth_maid_drop", "pair_master_doll", 100)
	
	maid:die(maid)
	
	game.add_item_to_group("lone_shoggoth_maid_drop", "broken_master_doll", 100)
	game.add_item_to_group("lone_shoggoth_maid_drop", "broken_maid_dress", 50)
	game.add_item_to_group("lone_shoggoth_maid_drop", "pair_master_doll", 0)
	
	game.add_msg("떠도는 메이드 씨를 구한걸까?")
		game.add_msg("그렇게 믿고 싶다.")
		salv_count = salv_count + 1
		player:set_value("MB_SALV_COUNT", tostring(salv_count))
	else
		game.add_msg("떠도는 메이드 씨의 움직임이 한순간 멈추었다...")
		game.add_msg("그러나 다시 날뛰기 시작했다...")
	end
	
	return true
end

game.register_iuse("IUSE_MAID_BELL", iuse_maid_bell)
game.register_iuse("IUSE_LITTLE_BELL", iuse_little_bell)
game.register_iuse("IUSE_LITTLE_CAKE", iuse_little_cake)
game.register_iuse("IUSE_LOVED_MAID", iuse_loved_maid)

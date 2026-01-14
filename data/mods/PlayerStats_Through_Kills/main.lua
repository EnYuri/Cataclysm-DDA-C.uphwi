local MOD = {}


-- 설정

-- 상승시키는 스텟을 플레이어가 지정할건가?
-- true:지정시킨다  false:랜덤 선택
local FragPlayerChoice = true

-- 몇 체를 쓰러뜨릴 때마다 스텟을 상승시키는가?
local SetKillCount = 100

-- 다음 강화 때 마다 추가되는 토벌 수 추가
local AddKillCount = 1
-- SetKillCount가100、AddKillCounter가10의 경우
-- 100체 토벌시 스텟 업
-- 210이후(110)번째를 두번째로, 330번째(120)으로 3회째
--  460 이후(130) 상승 마다, 600, 750 순으로 필요 수 증가

local StrUpMes		= "힘이 세졌다"
local DexUpMes	= "손재주가 더 좋아졌다"
local IntUpMes		= "머리가 똑똑해졌다"
local PerUpMes	= "감각이 좋아졌다"




-- 설정은 여기까지


if FragPlayerChoice ~= true then FragPlayerChoice = false end
if SetKillCount <= 0 then SetKillCount = 300 end





mods["StatsThroughKills"] = MOD

function MOD.on_new_player_created()
	Mod_KillStat_SetVar(SetKillCount, 0, 0, 0, 0, 0)
end

function MOD.on_minute_passed()
	Mod_KillStat_Main()
end



function Mod_KillStat_Main()
	local monster_types = game.get_monster_types()
	local i = 0
	local count = 0
	for _, monster_type in ipairs(monster_types) do
		i = i + 1
		local mtype = monster_type:obj()
		count = count + g:kill_count(mtype.id) -- 対象のキル数取得
	end
	
	local next_count, str_bonus, dex_bonus, int_bonus, per_bonus, pre_add = Mod_KillStat_GetVar()
	local up = 0
	while count >= next_count do
		up = up + 1
		pre_add = pre_add + AddKillCount
		next_count = next_count + SetKillCount + pre_add
	end
	
	if up > 0 then
		Mod_KillStat_PlayerDownRef(str_bonus, dex_bonus, int_bonus, per_bonus)
		for i=1, up do
			local stat = 0
			if FragPlayerChoice ~= true then -- ランダム
				stat = game.rng(0,3)
			else -- プレイヤー選択
				local menu = game.create_uimenu()
				menu.title = "["..i.."/"..up.."]상승시키는 스텟을 선택하라"
				menu:addentry("체력")
				menu:addentry("민첩")
				menu:addentry("지능")
				menu:addentry("감각")
			
				menu:query(true)
				stat = menu.selected
			end
		
			local s = ""
			if stat == 0 then
				s = StrUpMes
				 str_bonus =  str_bonus + 1
			elseif stat == 1 then
				s = DexUpMes
				 dex_bonus =  dex_bonus + 1
			elseif stat == 2 then
				s = IntUpMes
				 int_bonus =  int_bonus + 1
			elseif stat == 3 then
				s = PerUpMes
				 per_bonus =  per_bonus + 1
			end
			game.add_msg(s)
		end
	
		-- ステータス上昇結果反映
		Mod_KillStat_PlayerUpRef(str_bonus, dex_bonus, int_bonus, per_bonus)
		-- Mod用に保存
		Mod_KillStat_SetVar(next_count, str_bonus, dex_bonus, int_bonus, per_bonus, pre_add)
	end
end

function Mod_KillStat_PlayerDownRef(str, dex, int, per)
	player.str_max = player.str_max - str
	player.dex_max = player.dex_max - dex
	player.int_max = player.int_max - int
	player.per_max = player.per_max - per
end

function Mod_KillStat_PlayerUpRef(str, dex, int, per)
	player.str_max = player.str_max + str
	player.dex_max = player.dex_max + dex
	player.int_max = player.int_max + int
	player.per_max = player.per_max + per
	player:recalc_hp()
end

function Mod_KillStat_SetVar(addcount, str, dex, int, per, up)
	player:set_value("NextKillCount", tostring(addcount))
	player:set_value("KillStr", tostring(str))
	player:set_value("KillDex", tostring(dex))
	player:set_value("KillInt", tostring(int))
	player:set_value("KillPer", tostring(per))
	player:set_value("KillPreUp", tostring(up))
end

function Mod_KillStat_GetVar()
	return tonumber(player:get_value("NextKillCount")) or SetKillCount,
		tonumber(player:get_value("KillStr")) or 0,
		tonumber(player:get_value("KillDex")) or 0,
		tonumber(player:get_value("KillInt")) or 0,
		tonumber(player:get_value("KillPer")) or 0,
		tonumber(player:get_value("KillPreUp")) or 0
end





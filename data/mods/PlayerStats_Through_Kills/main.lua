local MOD = {}
mods["StatsThroughKills"] = MOD

-- =========================
-- 설정
-- =========================

-- 상승시키는 스텟을 플레이어가 지정할건가?
-- true: 지정 / false: 랜덤
local FragPlayerChoice = true

-- 몇 체를 쓰러뜨릴 때마다 스텟을 상승시키는가?
local SetKillCount = 100

-- 다음 강화 때 마다 추가되는 토벌 수 증가치
local AddKillCount = 5

local StrUpMes = "힘이 세졌다"
local DexUpMes = "손재주가 더 좋아졌다"
local IntUpMes = "머리가 똑똑해졌다"
local PerUpMes = "감각이 좋아졌다"

-- 세이브 중간에 모드 추가했을 때:
-- true  = 지금까지 누적 킬도 포함
-- false = 모드 설치 시점부터만 카운트
local CountPastKillsOnFirstInstall = true

local MaxUpsPerDay = 5

-- 디버그 메시지
local DEBUG_MSG = false

-- 설정 정리
if FragPlayerChoice ~= true then FragPlayerChoice = false end
if SetKillCount <= 0 then SetKillCount = 100 end
if AddKillCount < 0 then AddKillCount = 0 end
if MaxUpsPerDay <= 0 then MaxUpsPerDay = 1 end


local function total_kill_count()
	local count = 0
	for _, monster_type in ipairs(game.get_monster_types()) do
		local mtype = monster_type:obj()
		count = count + g:kill_count(mtype.id)
	end
	return count
end


local function is_inited()
	local v = player:get_value("KillStatInited")
	return (v ~= nil and v ~= "" and tonumber(v) == 1)
end

local function get_baseline()
	return tonumber(player:get_value("KillBaseline")) or 0
end

local function set_baseline(v)
	player:set_value("KillBaseline", tostring(v))
end

local function get_pending()
	return tonumber(player:get_value("KillPending")) or 0
end

local function set_pending(v)
	player:set_value("KillPending", tostring(v))
end

local function init_if_needed(is_new_player)
	if not player or not game or not g then return end
	if is_inited() then return end

	local existing_next = player:get_value("NextKillCount")
	if existing_next ~= nil and existing_next ~= "" then
		player:set_value("KillStatInited", "1")
		if player:get_value("KillBaseline") == nil or player:get_value("KillBaseline") == "" then
			set_baseline(0)
		end
		if player:get_value("KillPending") == nil or player:get_value("KillPending") == "" then
			set_pending(0)
		end
		if DEBUG_MSG then game.add_msg("StatsThroughKills: adopted existing save data") end
		return
	end

	local baseline = 0
	local total = total_kill_count()

	if (not is_new_player) and (CountPastKillsOnFirstInstall ~= true) then
		baseline = total
	end

	player:set_value("KillStatInited", "1")
	set_baseline(baseline)
	set_pending(0)

	-- 기존 키들 초기화
	Mod_KillStat_SetVar(SetKillCount, 0, 0, 0, 0, 0)

	if DEBUG_MSG then
		game.add_msg("StatsThroughKills: initialized (baseline=" .. tostring(baseline) .. ")")
	end
end


local function compute_new_ups(count, next_count, pre_add)

	if count < next_count then
		return 0, next_count, pre_add
	end

	local n = 0

	if AddKillCount == 0 then
		local step = SetKillCount + pre_add
		if step <= 0 then step = SetKillCount end
		n = math.floor((count - next_count) / step) + 1
		next_count = next_count + n * step
		return n, next_count, pre_add
	end

	-- 부등식:
	-- next_count + n*(SetKillCount+pre_add) + AddKillCount*n*(n+1)/2 <= count
	local A = AddKillCount / 2.0
	local B = (SetKillCount + pre_add) + (AddKillCount / 2.0)
	local C = next_count - count

	local D = B*B - 4*A*C
	if D < 0 then D = 0 end

	n = math.floor(( -B + math.sqrt(D) ) / (2*A))
	if n < 0 then n = 0 end

	local function threshold(nn)
		return next_count + nn*(SetKillCount + pre_add) + AddKillCount*nn*(nn+1)/2
	end

	while threshold(n+1) <= count do n = n + 1 end
	while n > 0 and threshold(n) > count do n = n - 1 end

	if n <= 0 then
		n = 1
	end

	pre_add = pre_add + n * AddKillCount
	next_count = threshold(n)

	return n, next_count, pre_add
end


local function Mod_KillStat_Main_Daily()
	local total = total_kill_count()
	local baseline = get_baseline()
	local count = total - baseline
	if count < 0 then count = 0 end

	local next_count, str_bonus, dex_bonus, int_bonus, per_bonus, pre_add = Mod_KillStat_GetVar()
	local pending = get_pending()

	local new_up, new_next, new_pre_add = compute_new_ups(count, next_count, pre_add)
	if new_up > 0 then
		pending = pending + new_up
		set_pending(pending)
		Mod_KillStat_SetVar(new_next, str_bonus, dex_bonus, int_bonus, per_bonus, new_pre_add)
	end

	if pending <= 0 then return end

	local pay = pending
	if pay > MaxUpsPerDay then pay = MaxUpsPerDay end

	Mod_KillStat_PlayerDownRef(str_bonus, dex_bonus, int_bonus, per_bonus)

	for i = 1, pay do
		local stat = 0

		if FragPlayerChoice ~= true then
			stat = game.rng(0, 3)
		else
			local menu = game.create_uimenu()
			menu.title = "["..i.."/"..pay.."] 상승시킬 스탯 선택 (남은 적립: "..tostring(pending - (i-1))..")"
			menu:addentry("힘")
			menu:addentry("민첩")
			menu:addentry("지능")
			menu:addentry("감각")
			menu:query(true)
			stat = menu.selected

			-- 취소(-1)하면 랜덤 처리
			if stat == nil or stat < 0 then
				stat = game.rng(0, 3)
			end
		end

		if stat == 0 then
			str_bonus = str_bonus + 1
			game.add_msg(StrUpMes)
		elseif stat == 1 then
			dex_bonus = dex_bonus + 1
			game.add_msg(DexUpMes)
		elseif stat == 2 then
			int_bonus = int_bonus + 1
			game.add_msg(IntUpMes)
		elseif stat == 3 then
			per_bonus = per_bonus + 1
			game.add_msg(PerUpMes)
		end
	end

	Mod_KillStat_PlayerUpRef(str_bonus, dex_bonus, int_bonus, per_bonus)

	pending = pending - pay
	if pending < 0 then pending = 0 end
	set_pending(pending)

	local nc, _, _, _, _, pa = Mod_KillStat_GetVar()
	Mod_KillStat_SetVar(nc, str_bonus, dex_bonus, int_bonus, per_bonus, pa)
end


function MOD.on_new_player_created()
	init_if_needed(true)
end

function MOD.on_day_passed()
	if not player or not game or not g then return end
	init_if_needed(false)

	if DEBUG_MSG then
		game.add_msg("StatsThroughKills: day hook fired")
	end

	Mod_KillStat_Main_Daily()
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

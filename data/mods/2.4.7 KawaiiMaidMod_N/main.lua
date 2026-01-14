-- Kawaii A&M Transport System(AMTS)

local MOD = {}

mods["KawaiiMaidMod"] = MOD

function MOD.on_day_passed()
	OnDay()
end

function MOD.on_new_player_created()
	Init()
end

-- ■毎日処理
function OnDay()
	if player:get_value("Kawaii_AMTS_Active") == "true" then
		Load_AMTS_Point()
		EditRP(0)
		cmsg("cyan", "AMTS 디바이스에 에너지가 충전되었습니다.")
		if AMTS_Rank < 5 then
			EditCharges(DNr, 1)
			EditCharges(DNt, 2)
		elseif AMTS_Rank < 8 then
			EditCharges(DNr, 2)
			EditCharges(DNt, 3)
		elseif AMTS_Rank < 10 then
			EditCharges(DNr, 3)
			EditCharges(DNt, 4)
		else
			EditCharges(DNr, 3)
			EditCharges(DNt, 6)
		end
		EditPoint(getDP())
		cmsg("cyan", "데일리 포인트:+" .. getDP() .. "/보유 포인트:" .. AMTS_Point)
	elseif player:get_value("Kawaii_AMTS_Added") == nil then --■既存キャラ用導入処理
		Init()
	end
end

-- ■新規プレイヤー
function Init()
	cmsg("light_green", "시야가 왜곡되더니, 갑자기 눈 앞에 근사한 상자가 나타났습니다... 이건 뭐지...?")
	player:i_add(item("kawaii_amts_box", 1))
	player:set_value("Kawaii_AMTS_Added", "true")
end


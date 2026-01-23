-- Kawaii A&M Transport System(AMTS)

-- ■납품アイテムid,ポイント
local pac_list = {
	"diamond", 1000,
	"kawaii_amts_pac_t1_01", 250,
	"kawaii_amts_pac_t1_02", 250,
	"kawaii_amts_pac_t1_03", 250,
	"kawaii_amts_pac_t2_01", 500,
	"kawaii_amts_pac_t2_02", 500,
	"kawaii_amts_pac_t2_03", 500
}
local pac_name = {}
local pac_point = {}
for i=1, #pac_list/2 do
	pac_name[i] = pac_list[(i*2)-1]
	pac_point[i] = pac_list[i*2]
end

-- ■一般アイテムid,cost,rank --ツール類が探索で揃ってるとR5までポイントが余るので上位납품をRankで制限してみる(v2.4.6)
local reward_list = {
	"bottle_plastic_small", 50, 1,
	"bottle_plastic", 100, 1,
	"detergent", 200, 2,
	"jar_glass", 150, 2,
	"kawaii_bottle_2l", 200, 2,
	"kawaii_jerrycan_10l", 300, 2,
	"kawaii_jerrycan_20l", 500, 2,
	"lighter", 100, 2,
	"emer_blanket", 300, 2,
	"picklocks", 750, 2,
	"nail", 500, 3,
	"duct_tape", 1000, 3,
	"small_storage_battery", 500, 3,
	"battery", 500, 3,
	"toolbox", 2000, 3,
	"welder", 3000, 3,
	"soldering_iron", 1500, 3,
	"solder_wire", 750, 3,
	"gunpowder", 500, 4,
	"copper", 500, 4,
	"30gal_drum", 1000, 4,
	"smokebomb", 500, 4,
	"flashbang", 500, 4,
	"EMPbomb", 750, 4,
	"generator_7500w", 2500, 4,
	"battery_ups", 1000, 4,
	"kawaii_portable_kitchen", 2000, 4,
	"e_tool", 1000, 4,
	"medium_storage_battery", 750, 5,
	"55gal_drum", 1500, 5,
	"atomic_lamp", 2000, 5,
	"1st_aid", 2000, 6,
	"bio_tools", 3000, 6,
	"solar_panel_v2", 1000, 6,
	"large_repairkit", 2500, 6,
	"anesthesia", 1000, 7,
	"bio_power_storage_mkII", 2000, 7,
	"omnicamera", 800, 7,
	"headlight_reinforced", 500, 7,
	"storage_battery", 1000, 8, --R8は2年目秋初め頃。2RP/D DP800(500*2+800=MAX1800P/D) 転送フルチャージ化
	"solar_panel_v3", 2000, 8,
	"kawaii_book_AM_illegal_recipe_box", 6000, 8,
	"bio_probability_travel", 5000, 9, --R9は3年目直前。해금 要素が恐らく最も少ない所…しかしここまできたらラストのR10まで行って色々해금 されたくなる
	"bio_speed", 5000, 9,
	"kawaii_cvd_kit", 10000, 9,
	"kawaii_hightend_mechanism", 10000, 9,
	"plut_cell", 3000, 10,
	"plasma", 6000, 10
}

-- ■素材系アイテム表示名,id,cost,rank --序盤の余ったポイントの受け皿と思いきや余らす状況で1~4x2程度では…R5あたりからDPとチャージ量と係数分で平時も…と思ったらR5からポイント需要が…
local material_list = {
	"비닐봉지", "bag_plastic", 200, 2,
	"재목", "2x4", 500, 2,
	"플라스틱 조각", "plastic_chunk", 500, 2,
	"가죽 조각", "leather", 500, 2, 
	"천 조각", "rag", 500, 2,
	"실타래", "thread", 500, 2,
	"고철", "scrap", 500, 2,
	"케블라 장갑판", "kevlar_plate", 1000, 4,
	"노멕스 조각", "nomex", 1000, 4
}

-- ■装備系アイテムid,cost,rank --消耗品系の用途が欲しい
local equip_list = {
	"kawaii_arrow_ribbon", 200, 2,
	"kawaii_crowbar_lance", 2500, 3,
	"kawaii_glass_bow", 4000, 3,
	"kawaii_secretpoach", 1500, 4,
	"kawaii_maid_hat_thermal_off", 2000, 5,
	"kawaii_maid_dress_ex", 3500, 5,
	"kawaii_arrow_feather", 750, 5,
	"kawaii_leila", 5000, 6,
	"kawaii_rita_and_rosa", 3500, 6,
	"kawaii_12shotgun", 4000, 6,
	"kawaii_crystal_td", 4000, 7,
	"kawaii_maid_hat_lss", 4500, 7,
	"kawaii_maid_dress_lss", 6500, 7,
	"kawaii_boots_hi", 1500, 7,
	"kawaii_shoes_hi", 1500, 7,
	"kawaii_death_scythe", 8500, 8,
	"kawaii_shelia_off", 7500, 8,
	"kawaii_arrow_little_mary", 2000, 9
}

-- ■液体表示名,内容量(L),id,コスト,ランク
local liquid_list = {
	"물", 2, "water", 250, 3, --R3は10日目。早ければ車両を触り始める頃？
	"깨끗한 물", 0.5, "water_clean", 300, 3,
	"램프 기름", 0.5, "lamp_oil", 500, 3,
	"휘발유", 0.5, "gasoline", 500, 3,
	"깨끗한 물", 2, "water_clean", 500, 4,
	"램프 기름", 2, "lamp_oil", 1000, 4,
	"휘발유", 2, "gasoline", 1000, 4,
	"물", 10, "water", 1000, 5, --R5は1年目秋終わり頃。基本的な物が揃う頃？ここからチャージ量とか変わるから1日あたり1.5RPとpacsys大のレシピ本で납품からのポイント倍加
	"휘발유", 10, "gasoline", 1500, 5,
	"경유", 10, "diesel", 1500, 5,
	"물", 20, "water", 1500, 7, --R7は2年目夏初め？
	"휘발유", 20, "gasoline", 2500, 7,
	"경유", 20, "diesel", 2500, 7
}

local l_name = {}
local l_amount = {}
local l_id = {}
local l_cost = {}
local l_rank = {}
for i=1, #liquid_list/5 do
	l_name[i] = liquid_list[(i*5)-4]
	l_amount[i] = liquid_list[(i*5)-3]
	l_id[i] = liquid_list[(i*5)-2]
	l_cost[i] = liquid_list[(i*5)-1]
	l_rank[i] = liquid_list[i*5]
end

-- ■あちこちで参照しそうなやつ
AMTS_Point = 0
AMTS_MaxPoint = 3
AMTS_RP = 0
AMTS_Rank = 1
AMTS_NextRP = 0
AMTS_JumpList_name = {}
AMTS_JumpCost = 50 --■텔레포트コスト
AMTS_reqRP = { 3, 7, 12, 15, 20, 25, 30, 50, 60, 9999 } --■ランク毎の要求RankPoint (※今は1季91日)デフォルトで1季14日、年56日 R1-4[1/D]R5-[1.5/D]R8-[2/D] R3=10 R5=37(27) R7=82(34) R8=112(23) R9=163(26) R10=223(30)
AMTS_DP = { 0, 100, 200, 400, 800, 2000 } --■2ランク毎に増える毎日の자동 적립 포인트
InitFlag_Point = 0

-- ■打つのがめんどくさい
DNr = "kawaii_amts_reciver"
DNt = "kawaii_amts_transmitter"
DNv = "kawaii_amts_point_viewer"

-- ■未해금 時のメニュー表記
local equipStr = "<color_dark_gray>[[잠겨 있습니다.]]:해금 Rank2</color>"
local materialStr = "<color_dark_gray>[[잠겨 있습니다.]]:해금 Rank2</color>"
local liquidStr = "<color_dark_gray>[[잠겨 있습니다.]]:해금 Rank3</color>"
local armsStr = "<color_dark_gray>[[잠겨 있습니다.]]:해금 Rank5</color>"


-- ■転送要請(アイテム入手)アイテムの処理
function amts_reciver(item2, active)
	Load_AMTS_Point()
	EditRP(0)

	if AMTS_Rank > 1 then
		equipStr = "장비전송"
		materialStr = "재료전송"
	end
	if AMTS_Rank > 2 then
		liquidStr = "액체전송"
	end
	if AMTS_Rank > 4 then
		armsStr = "AM-ARMS 컨트롤"
	end
	
	local c = CreateMenu("AMTS-전송(소유 포인트:" .. AMTS_Point .. "/Rank:" .. AMTS_Rank .. "/Next:" .. AMTS_NextRP ..")" , armsStr, "텔레포터 기동", "물자전달", materialStr, liquidStr, equipStr, "종료")
		if c == 0 then --■AM-ARMS 컨트롤
			if AMTS_Rank < 5 then
				cmsg("light_red", "이 커맨드는 Rank5부터 사용할 수 있습니다.")
				return
			end
			ARMSMenu("AM-ARMS 컨트롤(소유 포인트:" .. AMTS_Point .. "/Rank:" .. AMTS_Rank .. "/Next:" .. AMTS_NextRP .. ")")
			
		elseif c == 1 then --■テレポーターの起動
			amts_teleport(item2)
			
		elseif c == 2 then --■물자전달
			p3menu(reward_list,item2)
		
		elseif c == 3 then --■素材転送
			if AMTS_Rank < 2 then
				cmsg("light_red", "이 커맨드는 Rank2부터 사용할 수 있습니다.")
				return
			end
			p3menu(material_list,item2)
			
		elseif c == 4 then --■液体転送
			if AMTS_Rank < 3 then
				cmsg("light_red", "이 커맨드는 Rank3부터 사용할 수 있습니다.")
				return
			end
			local no = LiquidMenu("무엇을 전송받겠습니까?(소유 포인트:" .. AMTS_Point .. "/Rank:" .. AMTS_Rank .. "/Next:" .. AMTS_NextRP ..")")
			if no == #l_name then
				cmsg("cyan","취소했습니다.")
				return
			end
			
			no = no + 1
			local bottle = ""
			if l_amount[no] == 0.5 then
				bottle = "bottle_plastic"
			elseif l_amount[no] == 2 then
				bottle = "kawaii_bottle_2l"
			elseif l_amount[no] == 10 then
				bottle = "kawaii_jerrycan_10l"
			elseif l_amount[no] == 20 then
				bottle = "kawaii_jerrycan_20l"
			end

			local liquid = item(l_id[no],1)
			local it2 = StackLiquid(bottle,l_id[no],l_amount[no]/0.25)
			ReceiveItem(it2,l_cost[no],l_rank[no],item2.charges)
			
		elseif c == 5 then --■装備転送
			if AMTS_Rank < 2 then
				cmsg("light_red", "이 커맨드는 Rank2부터 사용할 수 있습니다.")
				return
			end
			p3menu(equip_list,item2)
			
		elseif c == 6 then

		else
			cmsg("red", "[kawaii error!!]선택한 ID가 범위 외입니다.(R1)")
		end
		
end

-- ■debug
function debugAdd(point)
	EditCharges(DNr, 6)
	EditCharges(DNt, 12)
	EditPoint(point)
	msg("DebugAdded!!")
end

-- ■3つの座標を表示する(debug)
function PosMSG(name)
	local p
	p = player:global_omt_location()
	msg2("omt", name, math.ceil(p.x), math.ceil(p.y), math.ceil(p.z))
	p = player:global_sm_location()
	msg2("sm", name, math.ceil(p.x), math.ceil(p.y), math.ceil(p.z))
	p = player:global_square_location()
	msg2("square", name, math.ceil(p.x), math.ceil(p.y), math.ceil(p.z))
end

-- ■3要素配列用転送メニュー(手抜き用)
function p3menu(list,item2)
	local title = "무엇을 전송받겠습니까?(소유 포인트:" .. AMTS_Point .. "/Rank:" .. AMTS_Rank .. "/Next:" .. AMTS_NextRP .. ")"
	local name, rank, cost = RewardListMenu(title,list)
	if name ~= nil then
		ReceiveItem(item(name,1),cost,rank,item2.charges)
	else
		cmsg("cyan", "취소했습니다.。")
	end
end

-- ■텔레포터 기동
function amts_teleport(it)
	LoadJumpList(it)
	local menu = game.create_uimenu()
	local choice = -1
	menu.title = "텔레포트할 위치를 선택하십시오(소유 포인트:" .. AMTS_Point .. "/Rank:" .. AMTS_Rank .. ")"
	local n = AMTS_JumpList_name
	
	for i = 0, 9 do
		local omx = tonumber(it:get_var("teleport_omx" .. i, "0"))
		local omy = tonumber(it:get_var("teleport_omy" .. i, "0"))
		local omz = tonumber(it:get_var("teleport_omz" .. i, "0"))
		local pstr = string.format("<color_dark_gray>(%s,%s,%s)</color>", math.ceil(omx), math.ceil(omy), math.ceil(omz))
		
		if i < AMTS_Rank + 1 then
			menu:addentry("<color_pink>[slot" .. math.ceil(i) .. "]</color>" .. n[i] .. pstr)
		else
			menu:addentry("<color_dark_gray>[slot" .. math.ceil(i) .. "]" .. " --- Locked(" .. "Rank" .. i ..  ") ---</color>")
		end
	end
	
	menu:addentry("종료")
	menu:query(true)
	local no = math.ceil(menu.selected)
	
	if no > #AMTS_JumpList_name then
		cmsg("cyan", "텔레포트를 취소했습니다.。")
		return
	end
	
	if no > AMTS_Rank then
		cmsg("light_red", "현재 Rank에선 사용할 수 없는 슬롯입니다.")
		return
	end
  
	local no2
	if no == 0 then
		no2 = CreateMenu("소유 포인트:" .. AMTS_Point .. "/" .. "[슬롯" .. no .. "]" .. AMTS_JumpList_name[no], "<color_light_green>["..AMTS_JumpCost.."Point]</color>텔레포트", "종료")
		if no2 == 0 then
			kawaii_teleport(it,no)
			return
		else
			cmsg("cyan", "텔레포트를 취소했습니다.。")
			return
		end
	end
	
	no2 = CreateMenu("[slot" .. no .. "]" .. AMTS_JumpList_name[no], "<color_light_green>["..AMTS_JumpCost.."Point]</color>텔레포트", "현재 위치 등록", "좌표 이름 수정", "종료")
	if no2 == 0 then --■텔레포트
		local no3 = CreateMenu("현재 좌표를 일시적으로 등록하시겠습니까?", "등록하고 텔레포트한다.", "등록하지않고 텔레포트한다.", "취소한다.")
		
		if no3 == 0 then --■一時登録あり
			if it:get_var("teleport_name" .. no, "null") == "null" then
				cmsg("light_red", "좌표가 기록되어 있지 않습니다.")
				return
			end
			
			local om = player:global_omt_location()
			local gpos = player:global_square_location()
			cmsg("cyan", "[Slot0] 임시 등록 좌표에 텔레포트 이전 좌표를 등록했습니다.")
			kawaii_teleport(it,no)
			kawaii_teleport_save(it, 0, "임시 등록 좌표", om, gpos)
			
		elseif no3 == 1 then --■一時登録なし
			kawaii_teleport(it,no)
			
		else --■취소한다.
			cmsg("cyan", "텔레포트를 취소했습니다.。")
			return
		end

	elseif no2 == 1 then --■登録
		local regname = game.string_input_popup("",30,"등록할 이름을 입력하십시오\n(입력을 취소한다.)")
		if regname == "" then
			cmsg("cyan", "텔레포트 목록 등록을 취소했습니다..")
			return
		end
		
		kawaii_teleport_save(it,no,regname)
		msg("[Slot%s]%s 에 현재 위치를 등록했습니다.", no, regname)
		
	elseif no2 == 2 then --■編集
		if it:get_var("teleport_name" .. no, "null") == "null" then
			cmsg("light_red", "미등록 슬롯의 이름은 수정할 수 없습니다.")
			return
		end
		
		local regname = game.string_input_popup("",30,"새 이름을 입력하십시오\n(입력을 취소한다.)")
		if regname == "" then
			cmsg("cyan", "텔레포트 목록에 등록된 이름의 수정을 취소했습니다..。")
			return
		end
		
		it:set_var("teleport_name" .. no, regname)
		cmsg("cyan", "[Slot%s]에 등록된 이름을 [%s]로 수정했습니다.", no, regname)
		
	else --■취소한다.
		return
	end

	function tmptp(it2,no2)

	end
end

-- ■텔레포트先名前リストのロード
function LoadJumpList(it)
	local name
	for i = 0, 9 do
		name = it:get_var("teleport_name" .. i, "미등록")
		if i == 0 then
			AMTS_JumpList_name[i] = "임시 등록 좌표"
		else
			AMTS_JumpList_name[i] = name
		end
	end
end

-- ■납품(ポイント入手)アイテムの処理
function amts_transmitter(item2, active)
	Load_AMTS_Point()
	EditRP(0)
	local c = CreateMenu("AMTS-납품(소유 포인트:" .. AMTS_Point .. "/Rank:" .. AMTS_Rank .. "/Next:" .. AMTS_NextRP ..")" , "납품한다","납품 아이템 목록", "AMTS 패키징 시스템을 받는다.", "종료")
	if c == 0 then
		local no = ItemListMenu("뭘 납품하시겠습니까?")
		if no == "noitem" then
			return
		end
		if no == nil or no == "cancel" then
			cmsg("cyan", "납품을 취소했습니다..。")
			return
		end
		
		SendItem(GetInvItem(pac_name[no]),pac_point[no],item2.charges)
	elseif c == 1 then
		cmsg("cyan", "납품 리스트를 확인합니다.")
		viewNouhin()
	elseif c == 2 then
		if item2.charges == 0 then
			cmsg("light_red", "충전량이 부족합니다.")
			return
		end
		
		player:i_add(item("kawaii_amts_pacsys",1))
		cmsg("cyan", "AMTS 패키징 시스템을 받았습니다.")
		EditCharges(DNt, -1)
	elseif c == 3 then
	
	else
		cmsg("red", "[kawaii error!!]선택한 ID가 범위 외입니다.(T1)")
	end
end

-- ■AMTSインストールキット(外箱のメモを読む)
function amts_kit(it, active)
	game.popup(gText("boxmemo"))
	cmsg("light_green", "근사한 상자를 열었다.")
	player:i_add(item("kawaii_amts_box2",1))
	player:i_add(item("kawaii_amts_manual",1))
	player:i_rem(it)
end

-- ■AMTSインストールキット(施術)
function amts_kit2(it, active)
	cmsg("light_green", "AMTS장치를 삽입했다.")
	player:set_value("Kawaii_AMTS_Active", "true")
	player:i_add(item("kawaii_amts_reciver", 1))
	player:i_add(item("kawaii_amts_transmitter", 1))
	player:i_add(item("kawaii_amts_point_viewer", 1))
	EditRP(0)
	EditPoint(0)
	player:i_rem(it)
end

-- ■AMTSマニュアルアイテムの処理
function amts_manual(it, active)
	game.popup(gText("manual_1"))
	game.popup(gText("manual_2"))
	game.popup(gText("manual_3"))
end

-- ■アイテム受取
function ReceiveItem(it,cost,rank,charges)
	if charges == 0 then
		cmsg("light_red", "충전량이 부족합니다.")
		return
	elseif rank > AMTS_Rank then
		cmsg("light_red", "랭크가 부족합니다.")
		return
	elseif cost > AMTS_Point then
		cmsg("light_red", "포인트가 부족합니다.")
		return
	end
	
	if it:ammo_type():str() == "battery" and it:typeId() ~= "kawaii_UPS" then
		local citem = item("battery",1)
		citem.charges = it:ammo_capacity()
		it:fill_with(citem)
	end
	
	if it:typeId() == "battery" then
		local citem = item("battery",1)
		citem.charges = AMTS_Rank * 100
		it = citem
	end
	
	if it:typeId() == "lighter" then
		it.charges = 100
	end
	
	local dname = it:display_name()
	local flag = 0
	local n = material_list
	local items = {}
	for i,v in pairs(n) do
		if it:typeId() == v then
			for i=1, AMTS_Rank*2 do
				player:i_add(it)
			end
			dname = it:display_name() .. " x" .. AMTS_Rank*2 .. "(Rank)"
			flag = 1
		end
	end

	if flag == 0 then
		player:i_add(it)
	end
	EditPoint(-(cost))
	EditCharges(DNr,-1)
	msg("<color_pink>[-" .. cost .. "Point]</color>" .. dname .. "  를(을) 전송했습니다.(소유 포인트:" .. AMTS_Point .. ")")
end

-- ■アイテム납품
function SendItem(item,point,charges)
	if charges == 0 then
		cmsg("light_red", "충전량이 부족합니다.")
		return
	end
	EditPoint(point)
	EditCharges(DNt, -1)
	player:i_rem(item)
	msg("<color_pink>[+" .. point .. "Point]</color>" .. item:display_name() .. " 를 납품했습니다. (소유 포인트:" .. AMTS_Point .. ")")
	EditRP(1)
end

-- ■ランクポイントの増減と関連処理(初期化ロードは0で)
function EditRP(point)
	AMTS_RP = tonumber(player:get_value("Kawaii_AMTS_RP"))
	
	if AMTS_RP == nil then
		AMTS_RP = 0
	end
	
	if AMTS_Rank == 10 then
		ATMS_Rank = 10
		AMTS_NextRP = 9999
		return
	end
	
	AMTS_RP = AMTS_RP + point
	
	local oldRank = AMTS_Rank
	local rp2 = AMTS_RP
	local i = 1
	local d = AMTS_reqRP[1]
	while AMTS_Rank < 10 and rp2 > 0 do
		if rp2 > AMTS_reqRP[i] - 1 then
			rp2 = rp2 - AMTS_reqRP[i]
		else
			break
		end
		i = i + 1
	end
	
	AMTS_Rank = i
	AMTS_NextRP = AMTS_reqRP[i] - rp2
	
	if point > 0 and AMTS_Rank > oldRank then
		cmsg("light_green", "AMTS랭크가 상승했습니다!!(Rank" .. i .. ")")
		local apt = "자동 적립 포인트" .. AMTS_DP[math.ceil(i/2)] .. "->" .. AMTS_DP[math.ceil(i/2)+1]
		local bonus = "전송 아이템 추가 "
		
		if i == 2 then
			bonus = bonus .. apt
			GiveItem("canteen")
			GiveItem("kawaii_raincoat")
		elseif i == 3 then
			bonus = bonus
			GiveItem("kawaii_crowbar_lance")
		elseif i == 4 then
			bonus = bonus .. apt
			GiveItem("kawaii_book_pacsys") --上位납품アイテムを해금 するレシピブック
		elseif i == 5 then
			bonus = bonus
			local ammo = item("kawaii_308AM",1)
			ammo.charges = 20
			local mag = item("kawaii_eve_mag",1)
			mag:put_in(ammo)
			local item = item("kawaii_amts_eve",1)
			item:put_in(mag)
			player:i_add(item)
			msg("<color_light_green>랭크 업 보너스:</color>" .. item:display_name())
			GiveItem("kawaii_scarf")
		elseif i == 6 then
			bonus = bonus .. apt
			GiveItem("kawaii_proto_bottle")
		elseif i == 7 then
			bonus = bonus
			GiveItem("kawaii_hitec_megane")
		elseif i == 8 then
			bonus = bonus .. apt
		elseif i == 9 then
			bonus = bonus
		elseif i == 10 then
			bonus = bonus .. apt
		end
		
		msg(bonus)
	end

	function GiveItem(itemstr)
		local item = item(itemstr,1)
		player:i_add(item)
		msg("<color_light_green>랭크 업 보너스:</color>" .. item:display_name())
	end

	player:set_value("Kawaii_AMTS_RP", tostring(AMTS_RP))
end

-- ■メニューテキスト用のランクとポイントを確認・表示・色分けして1行分返す
function MergeMenuText(name,rank,point,grayoutmode)
	local rankstr, coststr, name2
	local c = true

	if rank > AMTS_Rank then
		rankstr = "<color_dark_gray>[Rank" .. rank .. "]</color>" 
		c = false
	else
		rankstr = "<color_pink>[Rank" .. rank .. "]</color>" 
	end

	if point > AMTS_Point then
		coststr = "<color_dark_gray>[" .. point .. "Point]</color>"
		c = false
	else
		coststr = "<color_light_green>[" .. point .. "Point]</color>"
	end

	if grayoutmode == "false" then
		c = true --■一部の装備が強制的にgrayになるのではずしたい時がある
	end
	
	if c then
		name2 = rankstr .. coststr .. name
	else
		name2 = rankstr .. coststr .. "<color_dark_gray>" .. name .. "</color>"
	end
	
	return name2
end

-- ■ARMSメニュー
function ARMSMenu(title)
	local menu = game.create_uimenu()
	menu.title = title

	-- build option list dynamically (only if the item exists)
	local name = {}
	local cost = {}
	local rank = {}
	local itemid = {}

	local function add_opt(label, c, r, id)
		name[#name + 1] = label
		cost[#cost + 1] = c
		rank[#rank + 1] = r
		itemid[#itemid + 1] = id
	end

	-- base EVE
	if GetInvItem("kawaii_amts_eve"):typeId() ~= "null" then
		add_opt("EVE 탄창 장전(20)", 250, 5, "kawaii_amts_eve")
	end

	-- custom EVE
	if GetInvItem("kawaii_amts_eve_custom"):typeId() ~= "null" then
		add_opt("EVE(모델 불명) 탄창 장전(20)", 250, 5, "kawaii_amts_eve_custom")
	end

	-- no valid target
	if #name == 0 then
		cmsg("light_red", "장전할 EVE-Scout가 없습니다.")
		return
	end

	for i = 1, #name do
		local name2 = MergeMenuText(name[i], rank[i], cost[i], "false")
		menu:addentry(name2)
	end

	menu:addentry("종료")
	menu:query(true)

	local no = menu.selected

	-- exit / out of range (menu.selected is 0-based)
	if no < 0 or no >= #name then
		return
	end

	-- check rank/point AFTER validating selection
	if rank[no + 1] > AMTS_Rank then
		cmsg("light_red", "랭크가 부족합니다.")
		return
	end
	if cost[no + 1] > AMTS_Point then
		cmsg("light_red", "포인트가 부족합니다.")
		return
	end

	local eve_id = itemid[no + 1]
	local eve = GetInvItem(eve_id)
	if eve:typeId() == "null" then
		cmsg("red", "EVE-Scout를 찾지 못했습니다.")
		return
	end

	local cmag = eve:magazine_current()
	if not cmag then
		cmsg("red", "EVE-Scout에 탄창이 장전되어 있지 않습니다.")
		return
	end

	if EditCharges(DNr, -1) == 0 then
		return
	end

	player:i_rem(cmag)
	local mag = item(eve:magazine_default(), 1)
	local ammo = item("kawaii_308AM", 1)
	ammo.charges = 20
	mag:put_in(ammo)
	player:i_add(mag)

	EditPoint(-(cost[no + 1]))
	cmsg("cyan", "AMDS 안의 EVE 탄창이 장전되었습니다.")
end

-- ■液体がスタックできないのでforで回してitemで返す。液体が入ってる分他より気をつけて扱おう(うまい)
function StackLiquid(bottle,liquid,count)
	local item2 = item(bottle,1)
	
	for i=1,count do
		local lq = item(liquid,1)
		
		if item(liquid,1):has_temperature() then
			--msg("has_temp!!")
			lq:cold_up()
		else
			--msg("no_temp!!")
		end
		
		item2:fill_with(lq)
	end

	return item2
end

-- ■液体デバッグ
function debugLq(op)
	local bottle = item("kawaii_jerrycan_20l",1)
	local lq = item("water",2)
	lq:set_item_temperature(280)
	
	bottle:fill_with(lq)
	local res = bottle
	
	player:i_add(res)
	msg("debugLq finish")
	return
end

-- ■液体メニューリスト
function LiquidMenu(title)
	local menu = game.create_uimenu()
	local choice = -1
	menu.title = title
	local n = l_name

	for i in pairs(n) do
		local rankstr,coststr,name
		local c = true
		if l_rank[i] > AMTS_Rank then
			rankstr = "<color_dark_gray>[Rank" .. l_rank[i] .. "]</color>" 
			c = false
		else
			rankstr = "<color_pink>[Rank" .. l_rank[i] .. "]</color>" 
		end
		if l_cost[i] > AMTS_Point then
			coststr = "<color_dark_gray>[" .. l_cost[i] .. "Point]</color>"
			c = false
		else
			coststr = "<color_light_green>[" .. l_cost[i] .. "Point]</color>"
		end

		if c then
			name = rankstr .. coststr .. l_name[i] .. "(" .. l_amount[i] .. "L)"
		else
			name = rankstr .. coststr .. "<color_dark_gray>" .. l_name[i] .. "(" .. l_amount[i] .. "L)" .. "</color>"
		end
		
		menu:addentry(name)
	end
	
	menu:addentry("종료")
	menu:query(true)
	choice = menu.selected
	return choice
end

-- ■リワードリストを作る
function RewardListMenu(title,itemlist)
	local menu = game.create_uimenu()
	local choice = -1
	menu.title = title
	
	local dname = {}
	local name = {}
	local cost = {}
	local rank = {}
	if itemlist == material_list then
		local x = 4
		for i=1, #itemlist/x do
			dname[i] = itemlist[(i*x)-3]
			name[i] = itemlist[(i*x)-2]
			cost[i] = itemlist[(i*x)-1]
			rank[i] = itemlist[i*x]
		end
	else
		local x = 3
		for i=1, #itemlist/x do
			name[i] = itemlist[(i*x)-2]
			cost[i] = itemlist[(i*x)-1]
			rank[i] = itemlist[i*x]
		end
	end
	
	local n = name
	for i in pairs(n) do
		local it = item(name[i],1)
		
		if it:typeId() == "battery" then
			local citem = item("battery",1)
			citem.charges = AMTS_Rank * 100
			it = citem
		end
		
		if it:typeId() == "lighter" then
			it.charges = 100
		end
		
		local name2
		if itemlist == material_list then
			name2 = MergeMenuText(it:display_name() .. " x" .. AMTS_Rank*2 , rank[i], cost[i], "false")
		else
			name2 = MergeMenuText(it:display_name(), rank[i], cost[i], "false")
		end

		menu:addentry(name2)
	end
	
	menu:addentry("종료")
	menu:query(true)
	local no = menu.selected
	
	if no < #name then
		no = no+1
		return name[no], rank[no], cost[no]
	else
		return nil, nil, nil
	end
end

-- ■所持アイテムからリストを検索して납품リストを作る(持ってるものだけ表示)
function ItemListMenu(title)
	local menu = game.create_uimenu()
	local choice = -1
	menu.title = title
	local n = pac_name
	local has_list = {}
	local no = 0
	local count = 0
	
	for i in pairs(n) do
		if not GetInvItem(n[i]):is_null() then
			has_list[no] =  GetInvItem(n[i])
			menu:addentry("<color_light_green>[" .. pac_point[i] .. "Point]</color>" .. has_list[no]:display_name())
			has_list[no] = i
			no = no + 1
			count = count + 1
		end
	end
	if count == 0 then
		cmsg("light_red", "납품할 아이템이 없습니다.")
		return "noitem"
	end
	
	menu:addentry("종료")
	menu:query(true)
	choice = menu.selected
	if #has_list < choice then
		return "cancel"
	end
	return has_list[choice]
end

-- ■ポイントの増減
function EditPoint(point)
	if InitFlag_Point == 0 then
		local ampv = item("kawaii_amts_point_viewer",1)
		AMTS_MaxPoint = ampv:ammo_capacity()
		InitFlag_Point = 1
	end
	local item = GetInvItem("kawaii_amts_point_viewer")
	Load_AMTS_Point()
	AMTS_Point = AMTS_Point + point
	
	if AMTS_Point == AMTS_MaxPoint or AMTS_Point > AMTS_MaxPoint then
		AMTS_Point = AMTS_MaxPoint
		cmsg("light_red", "AMTS포인트가 한도에 도달했습니다.")
	end
	
	AMTS_Point = math.ceil(AMTS_Point)
	item.charges = AMTS_Point
	player:set_value("Kawaii_AMTS_Point", tostring(AMTS_Point))
end

-- ■ポイントをキャラデータからロード
function Load_AMTS_Point()
	AMTS_Point = tonumber(player:get_value("Kawaii_AMTS_Point"))
	if AMTS_Point == nil then
		AMTS_Point = 0
	end
end

-- ■デバイスのチャージを増減する
function EditCharges(name, point)
	local item = GetInvItem(name)
	if point > 0 then
		if math.floor(item.charges) < item:ammo_capacity() then
			msg(item:display_name() .. " 의 충전 금액+" .. point .. " =")
			item.charges = item.charges + point
			if item.charges > item:ammo_capacity() then
				item.charges = item:ammo_capacity()
				cmsg("light_red", item:display_name() .. "의 충전 금액이 한도에 도달했습니다.")
			end
			msg(item:display_name())
		else
			cmsg("light_red", item:display_name() .. " 는(은) 더 이상 충전할 수 없습니다.")
		end
	end
	if point < 0 then
		if math.floor(item.charges)  > 0 then
			item.charges = item.charges + point
		else
			cmsg("light_red", item:display_name() .. " 의 충전량이 부족합니다.。")
			return 0
		end
	end
	
	return 1
end

-- ■足下のアイテムを検索する
function getItemFloor(itemid)
	local stack = map:i_at(player:pos())
	local iter = stack:cppbegin()
	while iter ~= stack:cppend() do
		local tmp = iter:elem()
			if tmp:typeId() == itemid then
				return tmp
			end
		iter:inc()
	end
	return nil
end

-- ■インベントリ内のアイテムをid検索してitem型で返す
function GetInvItem(itemid)
	local i = -1
	local item = player:i_at(i)
	while i == -1 or item:typeId() ~= "null" do
		if tostring(item:typeId()) == itemid then
			item = player:i_at(i)
			break
		end
		i = i + 1
		item = player:i_at(i)
	end
	return item
end

-- ■납품アイテム確認用リストを表示
function viewNouhin()
	local text = "         <<  납품 아이템 목록  >>     \n"
	for i in pairs(pac_name) do
		text = text .. "<color_pink>[" .. pac_point[i] .. "Point]</color> " .. item(pac_name[i],1):display_name() .. "\n"
	end
	game.popup(text)
end

-- ■자동 적립 포인트を返す
function getDP()
	return AMTS_DP[math.floor(AMTS_Rank/2)+1]
end

-- ■地形idを返す
function getFloorID(point)
	local terrain_int_id = map:ter(point):to_i()
	local terrain = game.get_terrain_type(terrain_int_id)
	local terrain_str_id = terrain.id:str()
	return terrain_str_id
end

-- ■メニューつくる
function CreateMenu(title,...)
	local n = {...}
	local menu = game.create_uimenu()
	local choice = -1
	menu.title = title
	
	for i in pairs(n) do
		menu:addentry(n[i])
	end
	
	menu:query(true)
	choice = menu.selected
	return choice
end

-- ■テキストを書きやすく
function _(text)
    return tostring(text):gsub("^\t+", ""):gsub("\n\t+$", ""):gsub("(\n)\t+", "%1")
end

-- ■カラーメッセージ
function cmsg(color, ...)
	local str = "<color_" .. color .. ">" .. string.format(...) .. "</color>" .. " "
	game.add_msg(tostring(str))
end

-- ■変数カケール
function msg(...)
	local s = string.format(...)
	game.add_msg(s)
end

-- ■可変引数メッセージ(さくさくdebug用)
function msg2(msg,...)
	local n = {...}
	local str = msg
	for i in pairs(n) do
		str = str .. " : " .. n[i]
	end
	game.add_msg(tostring(str))
end

-- ■配列がsetできないのでforでぐるぐる
function ArraySave(list,name)
	for i = 1, #list do
		player:set_value(name .. i, list[i])
	end
end

-- ■配列がgetできないので
function ArrayLoad(list,name)
	for i = 1, #list do
		list[i-1] = player:get_value(name .. i)
	end
end

-- ■テキスト置き場
function gText(name)
	local text = "missing strings"
	--本文22行が限界っぽい
	if name == "boxmemo" then
		text = _[[
		                   <color_cyan>(상자에 붙어 있는 메모)</color>
		  이번에 A&M Transport System β 테스트에 응모해주셔서
		  정말로 감사합니다.
		  
		  엄격한 추첨 결과, 귀하께서 당첨되셨기에
		  여기 서비스를 이용하시는 데에 필요한 제품 세트를 보냈습니다.
		  
		  서비스 이용을 하시려면
		  동봉된 임플란트 시술 키트를
		  설명서를 잘 읽어보신 뒤 사용해보십시오.
		  
		  또한, 사전에 설명드린 대로
		  임플란트 시술을 하신다면 약관에 동의하신 것으로 간주되오니
		  이 점 양해 부탁드립니다.
		  
		  A&M Transport System 이 소중한 고객에게
		  좋은 서비스 경험 되시길 바랍니다.
		  
		  <color_light_blue>A&M Transport System</color>
		  <color_light_blue>β테스터 지원 데스크:</color>support@AM@AMTS
		]]
	end
	if name == "manual_1" then
		text = _[[
			 ---+---+---+---+   A&M Transport System<color_cyan>(AMTS)</color>   +---+---+---+--- 
			                         <color_cyan>(사용 설명서)</color> 1/3
			 
			<color_pink>【요약】</color>
			    체내에 소형 제어 장치를 삽입해서
			    A&M 기반의 양방향 차원 전송이 가능하게 되는 시스템 세트 및
			    임플란트 시술 키트입니다.
			<color_pink>【시술방법】</color>
			    1,동봉된 실린더의 두 곳에 있는 전원 버튼(그림 1)을 동시에 5초 이상
			       눌러서 전원을 킨다.
			 
			    2,실린더의 화면에 [준비 완료]가 뜰 때까지 기다린다.
			       (30초 정도)
			 
			    3,실린더의 ▼ 마크를 팔뚝(그림 2)에 맞춘다.
			       ※다른 장소에 시술하셔도 문제는 없지만
			         당사에서 했던 테스트의 결과, 팔뚝이 제일 불쾌감이 적었으므로
			         되도록이면 팔뚝에 시술하시기를 권합니다.
			 
			    4,그대로 실린더 상단의 버튼(그림3)을 누르면
			       나노 머신이 체내로 삽입돼서 시스템 구축・초기화합니다.
			 ---+---+---+---+---+---+---+--------+---+---+---+---+---+---+--- 
		]]
	end
	if name == "manual_2" then
		text = _[[
			 ---+---+---+---+   A&M Transport System<color_cyan>(AMTS)</color>   +---+---+---+--- 
			                         <color_cyan>(사용 설명서)</color> 2/3
			 
			<color_pink>【사용방법】</color>
			    각 작업은 뇌파 컨트롤로 이뤄집니다.
			     ※설명서에선 이를 VoiceImageControl(VIC)이라 씁니다.
			    머리 속으로, 발음하는 것처럼 이미지하셔서 명령을 지시하십시오.
			    기본 상태에선 각 명령에 대해서 머리 속에서
			    안내 음성이 재생되므로, 이를 따라 익숙해지는 걸
			    추천드립니다.
			<color_pink>【기존조작】</color>(VoiceImageControl 커맨드/상태)
			    <color_light_blue>[튜토리얼]/[ON,OFF]</color> : 튜토리얼 안내 전환
			    <color_light_blue>[헬프]/[검색 단어]</color> : 사용 방법을 음성 메시지로 안내받음
			    <color_light_blue>[전송]/[전송물의 시각적 심상 또는 ID]</color> : 물품 양방향 전송
			     ※수신시는 손바닥에 전송받는 물품이 있다고 이미지하십시오.
			     ※큰 물건을 보내실 땐 전용 패키지(P51)를 사용해주십시오.
			     ※보다 상세한 사용법과 요령은 P42(전송)을 참고하십시오.
			    <color_light_blue>[시간]/[ON/OFF]</color> : 시간을 시야 내에 표시(P5)
			    <color_light_blue>[온도]/[ON/OFF]</color> : 온도를 시야 내에 표시(P5)
			    <color_light_blue>[타이머]/[時間]</color> : 타이머를 시야 내에 표시(P5)
				 
			 ---+---+---+---+---+---+---+--------+---+---+---+---+---+---+--- 
		]]
	end
	if name == "manual_3" then
		text = _[[
			 ---+---+---+---+   A&M Transport System<color_cyan>(AMTS)</color>   +---+---+---+--- 
			                         <color_cyan>(사용 설명서)</color> 3/3
			     
			     <color_light_blue>[거리]/[대상물을 포인팅]</color> : 거리 측정(P4)(P7)
			     <color_light_blue>[가제트]/[파일]</color> : 가제트를 시야 내 표시(P4)(P8)
			     <color_light_blue>[메모]/[텍스트]</color> : 텍스트를 저장(P4)(P9)
			     <color_light_blue>[카메라]/[범위 지시]</color> : 시각 이미지 저장(P11)
			     <color_light_blue>[녹음]/[개시/정지]</color> : 음성 저장(P16)
			     <color_light_blue>[계산]/[방정식]</color> : 계산하기(P18)
			     <color_light_blue>[파일 열기]/[파일]</color> : 저장한 화상, 음성 표시(P4)(P19)
			 
				 
			 ---+---+---+---+---+---+---+--------+---+---+---+---+---+---+--- 
		]]
	end
	return text
end

-- ■神により記述された텔레포트関数群を弄ったもの
function tri_delta(a, b)
  return tripoint(a.x - b.x, a.y - b.y, a.z - b.z)
end

function kawaii_teleport(it,slot)
  local name = it:get_var("teleport_name" .. slot, "미등록")
  if slot == 0 then
  	name = it:get_var("teleport_name" .. slot, "임시 등록 좌표(미등록)")
  end
  if name == "미등록" or name == "임시 등록 좌표(미등록)" then
    cmsg("light_red", "좌표가 기록되어 있지 않습니다.")
    return 0
  end
  
  if AMTS_Point < AMTS_JumpCost then
  	cmsg("light_red", "포인트가 부족합니다.")
  	return
  end
  EditPoint(-AMTS_JumpCost)

  local omx = tonumber(it:get_var("teleport_omx" .. slot, "0"))
  local omy = tonumber(it:get_var("teleport_omy" .. slot, "0"))
  local omz = tonumber(it:get_var("teleport_omz" .. slot, "0"))
  local gx = tonumber(it:get_var("teleport_gx" .. slot, "0"))
  local gy = tonumber(it:get_var("teleport_gy" .. slot, "0"))
  local gz = tonumber(it:get_var("teleport_gz" .. slot, "0"))
  local om = tripoint(omx, omy, omz)
  local gpos = tripoint(gx, gy, gz)

  -- 近くにいるNPCを一緒に連れていく
  local npcs = {}
  local tmp_pos = player:pos()
  for dx = -10, 10 do
      for dy = -10, 10 do
          local npc_loc = tripoint(tmp_pos.x + dx, tmp_pos.y + dy, tmp_pos.z)
          local tmp_npc = game.get_npc_at(npc_loc)
          if tmp_npc then
              if tmp_npc:is_npc() then
                  table.insert(npcs, tmp_npc)
              end
          end
      end
  end
  
  g:place_player_overmap(om)
  local cur_gpos = player:global_square_location()
  local cur_pos = player:pos()

  -- player:pos()で取得できる座標はバッファ上の一時的な座標なので、
  -- global_square_locationで絶対座標を取得して補正する
  local delta = tri_delta(cur_gpos, gpos)
  player:setx(cur_pos.x - delta.x)
  player:sety(cur_pos.y - delta.y)
  player:setz(cur_pos.z - delta.z)

  -- NPCを再配置する
  tmp_pos = player:pos()
  for _,tmp_npc in ipairs(npcs) do
    for dx = -10, 10 do
        for dy = -10, 10 do
            local npc_loc = tripoint(tmp_pos.x + dx, tmp_pos.y + dy, tmp_pos.z)
            if not game.get_critter_at(npc_loc) then
                -- setposで座標を更新するとNPCが현재 overmapに現れる
                tmp_npc:setpos(npc_loc)
            end
        end
    end
  end
  g:reload_npcs()

  cmsg("cyan", "[Slot%s]%s 으로 텔레포트했습니다. (소유 포인트:%s)", slot, name, AMTS_Point)
  return 0
end

function kawaii_teleport_save(it,slot,name,om2,gpos2)
  local om,gpos
  if om2 == null then
    om = player:global_omt_location()
    gpos = player:global_square_location()
  else
    om = om2
    gpos = gpos2
  end
  
  it:set_var("teleport_name" .. slot, name)
  -- intで記憶するとなぜか読み出しが上手くいかないのでstringで記憶しておく
  it:set_var("teleport_omx" .. slot, tostring(om.x))
  it:set_var("teleport_omy" .. slot, tostring(om.y))
  it:set_var("teleport_omz" .. slot, tostring(om.z))
  it:set_var("teleport_gx" .. slot, tostring(gpos.x))
  it:set_var("teleport_gy" .. slot, tostring(gpos.y))
  it:set_var("teleport_gz" .. slot, tostring(gpos.z))

  -- msg("位置を記憶しました。")
  -- msg("Overmap (%d, %d, %d)", om.x, om.y, om.z)
  -- msg("Global square (%d, %d, %d)", gpos.x, gpos.y, gpos.z)
end


game.register_iuse("IUSE_KAWAII_AMTS_KIT", amts_kit)
game.register_iuse("IUSE_KAWAII_AMTS_KIT2", amts_kit2)
game.register_iuse("IUSE_KAWAII_AMTS_MANUAL", amts_manual)
game.register_iuse("IUSE_KAWAII_AMTR", amts_reciver)
game.register_iuse("IUSE_KAWAII_AMTT", amts_transmitter)

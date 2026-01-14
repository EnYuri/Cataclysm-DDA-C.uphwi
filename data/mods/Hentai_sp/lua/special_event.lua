--[[山羊頭の悪魔のイベント]]--
function event_goathead_demon(monster)
	local someone = monster:attack_target()

	--相手がいなければ何もしない。
	if (someone == nil) then
		return
	end
	--姿がプレイヤーに見えていなければ何もしない。相手に姿を見せてから名乗りをあげないとただの変な奴だし。
	if not(player:sees(monster:pos())) then
		return
	end

	--イベント発生用の特殊攻撃を無効化する。
	monster:disable_special("EVENT_GOATHEAD_DEMON")

	--TALK
	if (player:get_value(EVENT_GOATHEAD_DEMON)  == "met") then
		--会ったフラグがある場合のセリフ。激おこ。
		--the last part of the sentence would be something like: "your death alone will not satisfy me, I will have you burned/tortured in the deepest parts of hell forever!"
		--but I used the more concise variant, which is also a reference
		game.popup("\"...비열한 것! 언제까지 우리 앞길을 막아야 만족할 작정인가?!\r\n네놈에 대한 인내심이 바닥나고 있다... 결코 용서하지 않겠다!\r\n네놈은 죽어서도 자유롭지 못하리니, 네 영혼은 영원히 지옥불에 타오를 것이다!\"")
	else
		--会ったフラグが無い場合のセリフ。
		game.popup("\"이것좀 보게... 뭔가 수상한 일이 벌어지고 있다는 건 알고 있었다만, 그저 하찮은 인간이 주변을 기웃거리는 게군. \r\n영웅 놀음일 뿐인지, 아니면 그저 호기심인지? 어느쪽이든, 참으로 어리석군.\"")
		game.popup("\"이번 사바스는 우리 악마들에게 참으로 중요한 날이다. 우리가 지구를 장악하는 날이기 때문이지.\r\n네녀석이 누군지도 모르고 알고 싶지도 않다. 하지만 방해만큼은 용납할 수 없군.\r\n너는 내 손으로 여기서 끝을 맞이하게 될거다.\"")

		if (player.male) then
			game.popup("\"하지만 너무 걱정은 말거라. 네 비참한 영혼을 빼앗은 다음, 내 부하 악마로 친히 환생 시켜 줄 터이니!\r\n하하하-하하-하!!\"")
		else
			game.popup("\"하지만 자세히 보면.. 네년은 꽤 건강하고 활기찬 암컷으로 보이는군.\r\n아주 좋다, 네 영혼을 취한 다음엔.. 내가 원하는 만큼 네년을 사바스의 제물로 바치겠다!\r\n하하하-하하-하!\"")
		end

		--会ったフラグを立てる。
		player:set_value(EVENT_GOATHEAD_DEMON, "met")
	end

	--周囲にある魔法陣を起動する。
	local locs = get_around_locs(monster:pos(), 0, 10)
	for key, value in pairs(locs) do
		--DEBUG.add_msg("point.x:"..value.x)
		--DEBUG.add_msg("point.y:"..value.y)

		magic_circle_fire(value, 3, 30)
		magic_circle_summon(value, MON_ARCH_CUBI_LIST)
	end

	monster:mod_moves(-100)

end

--[[NPC"demonbeing_schoolgirl"を呼び出すイベント]]--
--[[
	NOTE:NPCを配置する場合、そのNPCにユニーク名称を付けなければ性別を固定することができない。
	しかしそうすると同一人物が複数存在する事になってしまう...そのため、\"その人物に会った事があるかあるかどうか\"をフラグとして管理し、
	会っていない場合はNPCを生成、既に会っている場合はモンスターを生成する仕様にする。
]]--
function event_demonbeing_schoolgirl(monster)

	--イベント発火地点を保持しておく。(ダミーモンスターを消すとnil参照で落ちるため)
	local tripoint = monster:pos()

	--なんかよくわからないけど、プレイヤーとの距離が離れすぎているとアボートするっぽい？ので、プレイヤーが近くにいない場合は処理を抜ける。
	local dist = game.distance(tripoint.x, tripoint.y, player:posx(), player:posy())		--line.cppを参照。
	if (dist > 10) then
		--DEBUG.add_msg("Out of range.")
		return
	end

	--ダミーモンスターは消す。
	g:remove_zombie(monster)

	if (player:get_value(EVENT_DEMONBEING_SCHOOLGIRL)  == "met") then
		--既に会ってる場合はモンスターを生成。
		local mon = game.create_monster(mtype_id("mon_corrupted_schoolgirl"), tripoint)

	else
		--まだ会ってない場合はNPCを生成。
		local npc_id = map:place_npc(tripoint.x, tripoint.y, npc_template_id("demonbeing_schoolgirl"))

		--会ったフラグを立てる。
		player:set_value(EVENT_DEMONBEING_SCHOOLGIRL, "met")
	end

end

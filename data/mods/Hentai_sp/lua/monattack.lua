--[[主にモンスター의特殊攻撃関連의処理を記述する。]]--

local body_part_texts = {
	"뺨", "입술", "귀", "손가락", "손", "팔", "가슴", "하복부", "고간", "음부", "엉덩이", "허벅지", "다리"
}

local action_texts = {
	"을(를) 어뤄만졌다.",
	"을(를) 쓰다듬어 올렸다.",
	"을(를) 부드럽게 주물렀다.",
	"을(를) 간드러지게 쓸어내렸다.",
	"을(를) 가볍게 쥐었다.",
	"을(를) 문질러 자극했다.",
	"을(를) 농락했다.",
	"에 키스했다.",
	"을(를) 혀로 핥았다.",
	"을(를) 핥아 올렸다.",
	"을(를) 빨았다.",
	"에 뜨거운 한숨을 내뱉었다."
}

local hip_action_texts = {
	"푹푹 쑤셨다.",
	"피스톤질 했다.",
	"마구 휘저었다.",
	"팡팡 부딪혔다.",
	"움직였다.",
	"위아래로 흔들었다.",
	"앞뒤로 흔들었다.",
	"규칙적으로 박아댔다."
}

--[[デバッグ用ファンクション]]--
function matk_hello(monster)
--function matk_hello(monster, target)
	--NOTE:LUA拡張版DDA은(는)target引数を持つmonster_attackが無いっぽい의で、monster:attack_target()で攻撃対象を取得している
	local target = monster:attack_target()

	game.add_msg("...who?")

	if (target == nil) then
		game.add_msg("who!?")
	else
		game.add_msg("Ah, it's you, "..target:disp_name().."!")
		game.add_msg(monster:disp_name()..":Hello, "..target:disp_name().."!")
	end

end

--[[↓こっから共通処理↓]]--


--[[monsterが攻撃しようとしているターゲットが射程距離内にいるかどうか判定し、可能な場合은(는)Creatureを返す。]]--
function get_attackable_target(monster, max_range)
	--攻撃しようとしているターゲットを取得
	local someone = monster:attack_target()

	if (someone == nil) then
		--DEBUG.add_msg("Um... never mind.")
		return
	end

	--DEBUG.add_msg("check distance ->")

	--ターゲットと의距離が最大射程よりも離れていたら何もしない
	local dist = game.distance(monster:posx(), monster:posy(), someone:posx(), someone:posy())		--line.cppを参照。
	if (dist > max_range) then
		--DEBUG.add_msg("Out of range.")
		return
	end
	--DEBUG.add_msg("OK!")

	--DEBUG.add_msg("Target is YOU, "..someone:disp_name().."!")

	return someone
end

function get_attackable_chara(monster, max_range)
	local target = get_attackable_target(monster, max_range)

	--PlayerかNPCだけを対象とする。
	if (target == nil or target:is_monster()) then
		--DEBUG.add_msg("not Character? Oh...")
		return
	end

	--NOTE:monster:attack_target()で取得できる의은(는)Creatureクラスな의でCharacterクラスを取り直してやる
	--local ret = g:character_at(target:pos())
	if target:is_player() then
		return player
	end
	local ret = game.get_npc_at(target:pos())

	return ret
end

function get_attackable_player(monster, max_range)
	local target = get_attackable_target(monster, max_range)

	--PlayerかNPCだけを対象とする。
	if (target == nil or target:is_monster()) then
		--DEBUG.add_msg("not Character? Oh...")
		return
	end

	--NOTE:monster:attack_target()で取得できる의은(는)Creatureクラスな의でPlayerクラスを取り直してやる
	--local ret = g:player_at(target:pos())
	if target:is_player() then
		return player
	end
	local ret = game.get_npc_at(target:pos())

	return ret
end

--[[四捨五入。実数numを、小数idp桁で丸める。ネット의拾い物]]
function math.round(num, idp)
	if (idp and idp > 0) then
		local mult = 10^idp
		return math.floor(num * mult + 0.5) / mult
	end
	return math.floor(num + 0.5)
end

--[[ハートマーク의二次曲線（いわゆるLove Formura）의tripointを計算する。ネット의拾い物]]
--[[
	NOTE:CDDA의仕様として、マップ의横軸xと縦軸y은(는)
	0-->x	右へ行くほど増
	|
	V
	y		下へ行くほど増
	의関係になっているため、数学的な二次曲線グラフと은(는)y軸を反転して考えてやる必要がある。
]]
function LoveFormula(center, radius, curvature)
	--DEBUG.add_msg("LoveFormula:start")

	local tripoint_list = {}
	--local center = player:pos()
	--DEBUG.add_msg("center:"..center.x.."/"..center.y)

	local y
	local b = curvature			--ハート曲線の曲がり具合。0だと完全な円になる。
	local dx = 1 / radius * 2	--xのループカウント刻み。刻みを小さくすると綺麗な曲線になるが処理が重くなる...
	local pos
	local rx
	local ry

	--ハート의曲線의tripointを計算
	-- 0 <= x <= 1, 0 <= y <= 1 의部分。つまり右上
	for x = 0, 1, dx do
		y = math.sqrt(1 - x * x) + b * math.sqrt(x)
		--DEBUG.add_msg("x="..x..", y="..y)

		--半径を考慮して丸めたpointを求める
		rx = math.round(x * radius, 0)
		ry = math.round(y * radius * -1, 0)

		pos = tripoint(rx + center.x, ry + center.y, 0)
		table.insert(tripoint_list, pos)

		--x反転箇所も確保しておく
		pos = tripoint(rx * -1 + center.x, ry + center.y, 0)
		table.insert(tripoint_list, pos)
	end

	-- 0 <= x <= 1, -1 <= y <= 0 의部分。つまり右下
	for x = 1, 0, dx * -1 do
		y = (math.sqrt(1 - x * x)) * -1 + b * math.sqrt(x)
		--DEBUG.add_msg("x="..x..", y="..y)

		--半径を考慮して丸めたpointを求める
		rx = math.round(x * radius, 0)
		ry = math.round(y * radius * -1, 0)

		pos = tripoint(rx + center.x, ry + center.y, 0)
		table.insert(tripoint_list, pos)

		--x反転箇所も確保しておく
		pos = tripoint(rx * -1 + center.x, ry + center.y, 0)
		table.insert(tripoint_list, pos)
	end

	--DEBUG.add_msg("LoveFormula:end")

	return tripoint_list
end


--[[targetがヤれる状態かどうか判定]]--
function can_wife(monster, target)
	local immobile_effect = {
		"webbed", "beartrap", "crushed", "grabbed", "in_pit", "sleep", "zapped"
	}

	if (target == nil) then
		return false
	end

	DEBUG.add_msg("wife target:"..target:disp_name())

	--ターゲットがぱんつ은(는)いてないかチェック
	if (target:wearing_something_on("bp_leg_l") and target:wearing_something_on("bp_leg_r")) then
		if (math.random(10) <= 2) then
			add_msg(monster:disp_name().."은(는) 당신의 비부를 노리고 있다...!", H_COLOR.YELLOW)
		end
		return false
	end

	DEBUG.add_msg("no wearing pants!")

	--ターゲットが身動き取れない状態かどうかチェック
	--targetが移動できない状態의場合은(는)ヤれる。適当な仕様。
	for key, value in pairs(immobile_effect) do
		if (target:has_effect(efftype_id(value))) then
			DEBUG.add_msg("immobile!")
			return true
		end
	end

	DEBUG.add_msg("can't wife.")

	return false
end

--[[イく判定]]--
function has_cum(me)
	--TODO:超適当な判定。

	local limit = 100		--v1.3から仕様変更。"lust"의intensityがこれを超えたら達する

	--"lust"의intensityを取得
	local intensity = me:get_effect_int(efftype_id("lust"))

	DEBUG.add_msg("intensity:"..intensity)

	if (intensity >= limit) then
		--"lust"を取り除き、少しだけwaitを掛ける。
		add_msg(ActorName(me, "은(는)", "은(는)").." 절정했다!", H_COLOR.GREEN)
		me:remove_effect(efftype_id("lust"))
		if not(me:is_monster()) then
			me:add_morale(morale_type("morale_orgasm"), game.rng( 1, 3 ), 0, HOURS(1), MINUTES(10))
		end
		me:mod_moves(-50)

		return true
	end

	return false
end

--[[対象의体液タイプ（アイテム）を取得する。]]--
function get_ejacuate_item(me)
	local liquid

	if ( me:is_player() or me:is_npc() ) then
		--対象がプレイヤーなら人間의体液。
		liquid = item("h_semen", 1)

	elseif (me:is_monster()) then
		--対象がモンスターなら魔性의体液。
		liquid = item("d_cum", 1)
	end

	if not(liquid == nil) then
		liquid:set_relative_rot(0)		--そ의ままだとbirthdayがゲーム開始時의ままな의で、ここで新鮮にする
	else
		DEBUG.add_msg("ERROR:ejacuate_item is nil.")
	end

	return liquid
end


--[[レイダー的な会話テキスト表示]]--
--TODO:メッセージ表示じゃなくて、"音"として会話させたい
--todo: proper speech for monsters isn't supported unfortunately, but it can still be a bit more sophisticated than this
function matk_vulgar_speech(monster)
	local max_range = 30		--特殊攻撃の最大射程

	--DEBUG.add_msg("vulgar_speech?")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		--今回のチェックで捕捉対象を見逃した場合はテキストを表示。
		if (monster:has_effect(efftype_id("target_acquired"))) then
			local speech_texts = VULGAR_SPEECH_TEXTS.TARGET_LOST
			add_msg(speech_texts[math.random(#speech_texts)], H_COLOR.YELLOW)

			monster:remove_effect(efftype_id("target_acquired"))
		end

	else
		if (monster:has_effect(efftype_id("target_acquired"))) then
			--交戦中の場合。
			local speech_texts = VULGAR_SPEECH_TEXTS.TARGET_ENGAGE
			add_msg(speech_texts[math.random(#speech_texts)], H_COLOR.YELLOW)

		else
			--今回のチェックで初めて対象を捕捉した場合。
			local speech_texts = VULGAR_SPEECH_TEXTS.TARGET_ACQUIRE
			add_msg(speech_texts[math.random(#speech_texts)], H_COLOR.YELLOW)

			monster:add_effect(efftype_id("target_acquired"), game.get_time_duration(1), "num_bp", true)
		end
	end

	--DEBUG.add_msg("vulgar_speech!")
end

--[[状態異常"corrupt"をtargetに与える。]]--
function gain_corrupt(target, dur)

	--対象のINT値の確率で抵抗判定。判定に失敗したら"corrupt"を与える。
	if (math.random(20) > target.int_cur) then
		target:add_effect(efftype_id("corrupt"), game.get_time_duration(dur))
		if target:is_player() then
			game.add_msg(ActorName(target, "은(는)", "은(는)").." 하복부로부터 뜨거운 욕정이 타고 오르는 것을 느꼈다!")
		end
	else
		game.add_msg("하지만..."..target:disp_name().."은(는) "..YouWord(target, "발정을", "욕정을").." 인내력으로 억눌렀다!")
	end

end


--[[↓こっからモンスター特殊攻撃処理↓]]--

--[[誘惑攻撃(近距離)]]--
function matk_seduce(monster)
	local max_range = 1		--特殊攻撃의最大射程

	--DEBUG.add_msg("seduce you?")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_chara(monster, max_range)

	if (target == nil) then
		return
	end

	--ここでモンスターに行動コストを追加。
	monster:mod_moves(-100)

	--==ターゲットの回避ロール==--
	--超回避システムが発動中なら必ず回避。
	if (target:uncanny_dodge()) then
		game.add_msg(monster:disp_name().."은(는)"..target:disp_name().."을(를) 노리고 접근했지만, 시간이 느리게 흘러가는 것처럼 느껴져 피해냈다!")
		return
	end

	--物理的な行動による回避ロール。player.dodge_roll()についてはmelee.cppとかを参照。
	if math.random(2) == 1 then
		if (math.random(100) <= target:dodge_roll()) then
			game.add_msg(monster:disp_name().."은(는)"..target:disp_name().."을(를) 노리고 접근했지만, 재빠르게 회피에 성공했다!")
			return
		end
	end

	--HENTAI的なテキストを取得。
	local bp_names = {table.unpack(body_part_texts)}

	--TODO:尾とか羽とか、特別な部位（特質）がある場合은(는)ここでbp_namesに追加しようと思ったけど力尽きた
	--I gotchu homie

	local bp_text = bp_names[math.random(#bp_names)]
	local act_text = action_texts[math.random(#action_texts)]

	--HENTAI的なテキストを表示。
	--modified to show variations better
	local output_text
	
	if (bp_text == "가슴" and math.random(10) <= 2) then
		output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." "..bp_text.."을(를) 애무했다."
    elseif (bp_text == "귀" and math.random(10) <= 2) then
		output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." "..bp_text.."을(를) 살짝 빨아 물었다."
    elseif (bp_text == "손" and math.random(10) <= 2) then
		output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." "..bp_text.."을(를) 꼭 쥐었다."
    elseif (act_text == "에 키스했다.") then
		if (bp_text == "입술") then
			output_text = monster:disp_name().." joins "..pro(monster, "his").." lips with "..ActorName(target, "'s")..", forcing "..pro(monster, "his").." tongue inside "..pro(target, "his").." mouth and enjoying "..((target:has_trait(trait_id("FORKED_TONGUE"))) and "the feel of "..ActorName(target, "'s").." unusually forked tongue" or "entwining "..YouWord(target, "your", "their").." tongues together").." while tasting each other's saliva"
		else
			output_text = monster:disp_name().."은(는) "..target:disp_name().."의 "..bp_text..""..act_text
		end
    elseif (math.random(10) <= 2) then
		if (target:has_trait(trait_id("TAIL_FLUFFY")) and math.random(10) <= 2) then
			output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." 부드러운 솜털 꼬리를 어루만졌다."
		elseif (target:has_trait(trait_id("TAIL_FIEND")) and math.random(10) <= 2) then
			output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." 악마 꼬리를 부드럽게 꼬아 문질렀다."
		elseif (target:has_trait(trait_id("TAIL")) and math.random(10) <= 2) then
			output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." 꼬리를 쓸어내렸다."
		elseif (target:has_trait(trait_id("WINGS")) and math.random(10) <= 2) then
			output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." 날개를 부드럽게 만질거렸다."
		else
			output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." 머리를 도담도담 쓰다듬었다."
		end
    elseif (math.random(10) <= 2) then
		output_text = monster:disp_name().."은(는) "..ActorName(target, "의").." 머리카락을 빗어 내렸다."
    else
       output_text = monster:disp_name().."은(는) "..target:disp_name().."의 "..bp_text.." "..act_text
    end
	--print
	add_msg(output_text..".", H_COLOR.PINK)

	--状態異常"lust"と"corrupt"をtargetに与える。
	--target:add_effect(efftype_id("corrupt"), game.get_time_duration(100))
	gain_corrupt(target, 100)
	target:add_effect(efftype_id("lust"), game.get_time_duration(4))

	--DEBUG.add_msg("seduce you!")
	
end

--[[誘惑攻撃(遠距離)]]--
function matk_tkiss(monster)
	local max_range = 10		--特殊攻撃의最大射程

	--DEBUG.add_msg("kiss you?")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_chara(monster, max_range)

	if (target == nil) then
		return
	end
	
	--ここでモンスターに行動コストを追加。
	monster:mod_moves(-50)

	--==ターゲットの回避ロール==--
	--超回避システムが発動中なら必ず回避。
	if (target:uncanny_dodge()) then
		game.add_msg(monster:disp_name().."은(는) "..target:disp_name().."을(를) 향해 키스를 날리려고 했지만, "..target:disp_name().."은(는) 순간 시간이 느리게 느껴져 회피했다!")
		return
	end

	--物理的な行動による回避ロール。...投げキッスって回避するとかそういう物じゃない気もするが
	if math.random(3) == 1 then
		if (math.random(100) <= target:dodge_roll()) then
			game.add_msg(monster:disp_name().."은(는) "..target:disp_name().."을(를) 향해 키스를 날리려고 했지만, "..target:disp_name().."은(는) 재빠르게 회피했다!")
			return
		end
	end

	add_msg(monster:disp_name().."은(는) "..target:disp_name().."을(를) 향해서 키스를 날렸다!", H_COLOR.PINK)

	--状態異常"lust"と"corrupt"をtargetに与える。
	--target:add_effect(efftype_id("corrupt"), game.get_time_duration(50))
	gain_corrupt(target, 50)
	target:add_effect(efftype_id("lust"), game.get_time_duration(2))

	--DEBUG.add_msg("kiss you!")

end


--[[脱がす攻撃]]--
function matk_stripu(monster)
	local max_range = 1			--特殊攻撃의最大射程
	local max_value = 250		--脱がしたアイテムを置くか奪うか의基準体積(mL。jsonで指定されてるvolume=1(c)은(는)250(mL)의扱いになる。)

	--DEBUG.add_msg("strip you?")

	--ヤってる最中은(는)脱がさない。着衣プレイっていいよね...
	if (monster:has_effect(efftype_id("dominate"))) then
		return
	end

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_chara(monster, max_range)

	if (target == nil) then
		return
	end

	--set naked check to disable this attack if target is already naked
	if (is_naked(target)) then
		return
	end

	--ここでモンスターに行動コストを追加。
	monster:mod_moves(-100)

	--ターゲットが着用しているアイテム의1つをランダムに取得。
	local item = get_random_wear(target)

	if (item == nil) then
		--DEBUG.add_msg("Nothing? Noooo...")
		return
	end

	--==ターゲットの回避ロール==--
	--超回避システムが発動中なら必ず回避。
	if (target:uncanny_dodge()) then
		game.add_msg(monster:disp_name().."은(는)"..target:disp_name().."의 "..item:display_name().."을(을) 벗기려고 했지만, "..YouWord(target, "은(는) 순간에", "은(는) 순간").." 시간이 느리게 느껴져 회피했다!")
		return
	end

	--物理的な行動による回避ロール。
	if math.random(2) == 1 then
		if (math.random(100) <= target:dodge_roll()) then
			game.add_msg(monster:disp_name().."은(는)"..target:disp_name().."의 "..item:display_name().."을(을) 벗기려고 했지만, "..YouWord(target, "은(는) 재빨리", "은(는) 빠르게").." 회피했다!")
			return
		end
	end

	--DEBUG.add_msg(item:display_name())

	--脱がす！
	--NOTE:player:takeoff()だと確認プロンプトが出てしまう의で、追加→削除의流れで脱がす。
	local vol = item:volume()
	--DEBUG.add_msg("volume:"..vol:value())
	
	if (vol:value() > max_value) then
		--item의体積が大きい場合은(는)monster의足元に落とす。
		game.add_msg("<color_pink>"..monster:disp_name().."은(는)"..ActorName(target, "의").." </color>"..item:display_name().."<color_pink>을{를} 슬그머니 벗겼다!</color>")
		map:add_item(monster:pos(), item)
	else
		--item의体積が十分に小さい場合（たとえば下着）은(는)monster의所持品に含める。
		game.add_msg("<color_pink>"..monster:disp_name().."은(는)"..ActorName(target, "의").." </color>"..item:display_name().."<color_pink>을{를} 벗겨내고 빼앗아버렸다!</color>")
		monster:add_item(item)
	end
	if (target:has_item(item)) then
		target:i_rem(item)
	end

	--DEBUG.add_msg("strip you!")

	return
end

--[[Wife攻撃]]--
--TODO:functionを分ける。神クラスになりかけてる
--todo - perhaps add dialogue for monster attacks?
function matk_wifeu(monster)
	local max_range = 1		--特殊攻撃의最大射程

	--DEBUG.add_msg("wife you?")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		return
	end

	--ターゲットがヤれる状態かどうかチェック
	if (not can_wife(monster, target)) then
		--直前までヤってたならモンスターから"dominate"を外し、対象からも"gotwifed"のintensityを1つ下げる。
		--FIXME:PRETTY BUGGY. プレイヤーとNPCを二人同時に相手してたり、ヤってる途中に死んだりすると対象に"gotwifed"が残ったままになってしまう。
		if (monster:has_effect(efftype_id("dominate"))) then
			monster:remove_effect(efftype_id("dominate"))
			target:add_effect(efftype_id("gotwifed"), game.get_time_duration(-1), "num_bp", true)
		end

		return
	end
	
	--added bunch of synonyms to keep it interesting
	local hip_act_text = hip_action_texts[math.random(#hip_action_texts)]

	--ヤる！
	if (monster:has_effect(efftype_id("dominate"))) then
		game.add_msg("<color_pink>"..monster:disp_name().."은(는) 허리를 "..hip_act_text.."...</color>")

	else
		local intensity = target:get_effect_int(efftype_id("gotwifed"))
		DEBUG.add_msg("intensity: "..intensity)

		if (intensity >= 3) then
			--ターゲットが既にお取り込み中の場合は...自主トレを行う。
			add_msg(monster:disp_name().." enjoys the show while staring at "..target:disp_name().." as "..pro(monster, "he").." plays with "..pro(monster, "himself").."...", H_COLOR.PINK)
			--add_msg(monster:disp_name().." 은(는) "..target:disp_name().."이(가)"..pro(monster, "he").." 농락당하는 광경을 보며"..pro(monster, "himself").." 즐겼다...", H_COLOR.PINK)

			monster:add_effect(efftype_id("lust"), game.get_time_duration(6))
			monster:mod_moves(-100)

			return

		else
			--スペースがあれば突っ込む。何をとは言わんが。
		    add_msg(monster:disp_name().."은(는) "..target:disp_name().."을(를) 억누르면서 느긋하게 허리를 아래로 내리기 시작했다...", H_COLOR.PINK)

			--モンスターに"dominate"を、対象に"gotwifed"を与える。
		    monster:add_effect(efftype_id("dominate"), game.get_time_duration(1), "num_bp", true)
			target:add_effect(efftype_id("gotwifed"), game.get_time_duration(1), "num_bp", true)
			
			lost_virgin(target, false, monster)
		end
	end

	--状態異常"corrupt"をtargetに与える。
	--target:add_effect(efftype_id("corrupt"), game.get_time_duration(200))
	gain_corrupt(target, 200)

	--状態異常"lust"をtargetとmonster両方に与える。
	target:add_effect(efftype_id("lust"), game.get_time_duration(8))

	--monsterの方は相手の器用の分だけプラス。
	--こう何というか、先にイった方が負けみたいなバトルを繰り広げたいけどバランスをどうすればいいんだ
	monster:add_effect(efftype_id("lust"), game.get_time_duration(8 + target.dex_cur))


	--イく！
	if (has_cum(target)) then
		local liquid = get_ejacuate_item(target)
		map:add_item(target:pos(), liquid)
	end
	if (has_cum(monster)) then
		local liquid = get_ejacuate_item(monster)
		map:add_item(monster:pos(), liquid)

		if (is_cubi(monster)) then
			--1/5の確率で相手に"FIEND"タイプの変異を与える。どこに注がれたかはこの際考慮しない。血清注射でも変異するんだからどこの穴でも[自主規制]
			--if (1 >= math.random(5)) then
			if (game.one_in(5)) then
				DEBUG.add_msg("mutate!")
				add_msg("마성의 체액이 "..ActorName(target, "의").." 몸에 스며들며 변이를 촉발시킨다...!", H_COLOR.YELLOW)
				target:mutate_category("FIEND")
			end
		end

		--妊娠チェック。やればできる。
		DEBUG.add_msg("preg roll-->")
		--TODO:共通化したい

		if not(target.male) then
			local mtype = monster.type
			if (mtype:in_species(species_id("MALE")) or mtype:in_species(species_id("HERM"))) then
				DEBUG.add_msg("male and female.")
				DEBUG.add_msg("mtype.id : "..mtype.id:str())

				if (is_cubi(monster)) then
					target:set_value(CREAMPIE_SEED_TYPE, "FIEND")
				else
					target:set_value(CREAMPIE_SEED_TYPE, "HUMAN")
				end

				--判定に成功すれば孕む。失敗しても5日くらい溜まったままにする。
				if (preg_roll(target)) then
					DEBUG.add_msg("impregnated.")
					target:add_effect(efftype_id("impregnated"), game.get_time_duration(1), "num_bp", true)
				else
					DEBUG.add_msg("not impregnate.")
					target:add_effect(efftype_id("creampie"), game.get_time_duration(72000))
				end

			end
		end

		--一時的に友好的に近づける。でないとrape loopに嵌ってしまう...
		--TODO:それでも複数に囲まれると死ぬまで嬲られるのをどうにかしたい
		monster.anger = monster.anger - 50
		monster.friendly = monster.friendly + 50
		monster.morale = monster.morale - 30

		--モンスターから"dominate"を外し、対象からも"gotwifed"のintensityを1つ下げる。
		monster:remove_effect(efftype_id("dominate"))
		target:add_effect(efftype_id("gotwifed"), game.get_time_duration(-1), "num_bp", true)
	end

	--DEBUG.add_msg("wife you!")

	target:mod_moves(-100)
	monster:mod_moves(-100)

	return
end

--[[ハート炎攻撃]]--
function matk_loveflame(monster)
	local max_range = 15		--特殊攻撃の最大射程

	DEBUG.add_msg("love flame?")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_target(monster, max_range)

	if (target == nil) then
		return
	end

	--ここでモンスターに行動コストを追加。
	monster:mod_moves(-200)

	local tripoint_list = LoveFormula(target:pos(), 15, 0.6)

	for key, value in pairs(tripoint_list) do
		--DEBUG.add_msg("key:"..key)
		--DEBUG.add_msg("value:"..value.x..", "..value.y)
		map:add_field(value, "fd_fire", 10, game.get_time_duration(10))
		--g:draw()
		--g:draw_ter(value)
	end

	game.add_msg(monster:disp_name().."가 주문을 외우니 "..target:disp_name().."사방이 불바다가 됐다!")

	DEBUG.add_msg("love flame!")
end

--[[露出攻撃。...攻撃？]]--
function matk_expose(monster)
	local max_range = 30		--特殊攻撃の最大射程

	DEBUG.add_msg("expose?")

	--周辺に存在するplayerをすべて取得する
	local player_list = get_players()
	local target_list = {}

	local dist
	for key, value in pairs(player_list) do

		DEBUG.add_msg("key:"..key)
		DEBUG.add_msg("value:"..value:disp_name())

		dist = game.distance(monster:posx(), monster:posy(), value:posx(), value:posy())		--line.cppを参照。

		--対象が射程内であればリストに追加する
		if (dist <= max_range) then
			table.insert(target_list, value)
		end

	end

	--対象が存在するなら
	if (#target_list > 0) then
		--ここでモンスターに行動コストを追加。
		monster:mod_moves(-500)

		if (player:sees(monster:pos())) then
			local rnd = math.random(3)

			if (rnd == 1) then
				add_msg(monster:disp_name().."이(가) 옷을 벗어내리며 드러낸 자신의 요염한 나신을 과시해 온다!", H_COLOR.PINK)
			elseif (rnd == 2) then
				add_msg(monster:disp_name().."은(는) 자신의 모든 것을 내보이면서 달콤한 목소리로 유혹을 해왔다!", H_COLOR.PINK)
			else
				add_msg(monster:disp_name().."은(는) 스스로의 손으로 음부를 문지르며 안타까운 교성을 울리기 시작했다!", H_COLOR.PINK)
			end

		end

		for key, value in pairs(target_list) do
			--対象にモンスターの姿が見ているなら"lust"と"corrupt"を与える。
			if (value:sees(monster:pos())) then
				--value:add_effect(efftype_id("corrupt"), game.get_time_duration(600))
				gain_corrupt(value, 600)
				value:add_effect(efftype_id("lust"), game.get_time_duration(24))
			end
		end
	end

	DEBUG.add_msg("expose!")
end

--[[↓こっからは魔法系統↓]]--

--[[沈静ガス攻撃]]--
function magic_relax_circle(monster, target)
	DEBUG.add_msg("relax_circle?")

	local tripoint_list = LoveFormula(target:pos(), 3, 0)
	for key, value in pairs(tripoint_list) do
		map:add_field(value, "relax_gas", 3, game.get_time_duration(20))
	end

	if (player:sees(monster:pos())) then
		game.add_msg(monster:disp_name().."이(가) 주문을 외우자, "..target:disp_name().."의 주변이 달콤한 향의 가스로 뒤덮였다!")
	end

	DEBUG.add_msg("relax_circle!")

end

--[[火の輪攻撃]]--
function magic_fire_circle(monster, target)
	DEBUG.add_msg("fire_circle?")

	local tripoint_list = LoveFormula(target:pos(), 6, 0)
	for key, value in pairs(tripoint_list) do
		map:add_field(value, "fd_fire", 1, game.get_time_duration(10))
	end

	if (player:sees(monster:pos())) then
		game.add_msg(monster:disp_name().."이(가) 주문을 외우자, "..target:disp_name().."의 주변이 거센 화염으로 휩싸였다!")
	end

	DEBUG.add_msg("fire_circle!")

end

--[[睡眠攻撃]]--
function magic_sleep(monster, target)
	DEBUG.add_msg("sleep you?")

	if (player:sees(monster:pos())) then
		game.add_msg(monster:disp_name().."은(는)"..target:disp_name().."에게 삿대질을 하면서 저주했다!")
	end
	target:add_effect(efftype_id("magic_sleepy"), game.get_time_duration(900))

	DEBUG.add_msg("sleep you!")

end

--[[引き寄せ攻撃]]--
function magic_pull_close(monster, target)
	DEBUG.add_msg("pull_close you?")

	--引き寄せる場所の候補リストを取得。
	local locate_list = get_around_empty_locs(monster:pos())
	if (#locate_list == 0) then
		--万が一引き寄せる場所が無い場合は何もしない。
		return
	end

	--場所の候補からランダムで1つ選択し、対象の位置を移動させる。
	local locale = locate_list[math.random(#locate_list)]
	target:setpos(locale)
	game.add_msg(ActorName(target, "이(가)", "은(는)").."텔레포트 당했다!")

	DEBUG.add_msg("pull_close you!")

end

--[[魔法陣描き攻撃。魔法陣に限らずトラップ全般に使える？]]--
function magic_write_circle(monster, tripoint, str_id)
	DEBUG.add_msg("write_circle?")

	local tmp = map:tr_at(tripoint)
	--NOTE:trapオブジェクトの実態はint型のため、「:str()」を付けてstring型の名称を取得してやる。
	--対象場所に既に別のトラップが存在するなら何もしない。
	if not(tmp.id:str() == "tr_null") then
		DEBUG.add_msg("error:another trap is already here.")
		return
	end

	--描き対象の魔法陣trapを取得する。("trap_str_id"メタテーブル)
	local circle = trap_str_id(str_id)

	--トラップを設置する。
	map:trap_set(tripoint, circle:id())	--trapオブジェクトの実態であるint型は「:id()」で取得できる。


	if (player:sees(monster:pos())) then

		if (player:sees(tripoint)) then
			game.add_msg(monster:disp_name().." 은 지면에 그려진 마법진을 발견했다!")
		end

	else
		if (player:sees(tripoint)) then
			game.add_msg("갑자기, 발밑에 형형히 빛나는 마법진이 떠오른다!")
		end
	end

	DEBUG.add_msg("write_circle!")

end

--[[魔法詠唱]]--
function spell_charge(monster)
	DEBUG.add_msg("spell_charge-->")

	monster:add_effect(efftype_id("spell_charge"), game.get_time_duration(EFF_SPELL_CHARGE_INT_FACTOR))

	if (player:sees(monster:pos())) then
		if (monster:has_effect(efftype_id("spell_charge"))) then
			game.add_msg(monster:disp_name().."은(는) 주문을 외우고 있다...")
		else
			game.add_msg(monster:disp_name().."은(는) 주문을 시전했다.")
		end

	else
		game.add_msg("누군가가 속삭이는 소리가 들려온다...")
	end

	--monster:add_effect(efftype_id("spell_charge"), game.get_time_duration(1), "num_bp", true)
	
end


--[[魔法陣（召喚）の起動]]--
function magic_circle_summon(tripoint, monster_id_list)
	DEBUG.add_msg("circle_summon?")

	local trap = map:tr_at(tripoint)

	--NOTE:trapオブジェクトの実態はint型のため、「:str()」を付けてstring型の名称を取得してやる。
	--DEBUG.add_msg("trap.id:"..trap.id:str())

	--trapが無ければ何もしない。
	if (trap.id:str() == "tr_null") then
		return
	end

	--トラップ"tr_magic_circle_summon"が指定位置にある場合は起動する。
	if (trap.id:str() == "tr_magic_circle_summon") then

		--...魔法陣の上に何かが乗っている場合は出てこれない。
		if not(g:is_empty(tripoint)) then
			if (player:sees(tripoint)) then
				game.add_msg("마법진은 무언갈 소환하려고 했던것 같지만, 장애물에 막혀 실패한것 같다.")
			end
			return
		end

		--起動した魔法陣は取り除く。
		map:remove_trap(tripoint)

		--monster_id_listの中からランダムで対象を選択し、召喚する。
		local mon = game.create_monster(mtype_id(monster_id_list[math.random(#monster_id_list)]), tripoint)

		if (player:sees(tripoint)) then
			game.add_msg("마법진이 무언가를 소환했다!")
		end

		--召喚して即動かれるとゲームバランス的にあれなので、ここで召喚したモンスターに行動コストを追加。
		mon:mod_moves(-200)

	end

	DEBUG.add_msg("circle_summon!")

end

--[[魔法陣（火炎）の起動]]--
function magic_circle_fire(tripoint, density, age)
	DEBUG.add_msg("circle_fire?")

	local trap = map:tr_at(tripoint)

	--NOTE:trapオブジェクトの実態はint型のため、「:str()」を付けてstring型の名称を取得してやる。
	--DEBUG.add_msg("trap.id:"..trap.id:str())

	--trapが無ければ何もしない。
	if (trap.id:str() == "tr_null") then
		return
	end

	--トラップ"tr_magic_circle_fire"が指定位置にある場合は起動する。
	if (trap.id:str() == "tr_magic_circle_fire") then

		--起動した魔法陣は取り除く。
		map:remove_trap(tripoint)

		--火を発生させる。
		map:add_field(tripoint, "fd_fire", density, game.get_time_duration(age))

		if (player:sees(tripoint)) then
			game.add_msg("마법진이 화염으로 폭발한다!")
		end
	end

	DEBUG.add_msg("circle_fire!")

end


--[[↓"どのモンスターが何の魔法をどのくらいの溜め・威力で使えるかを個別に設定する"↓]]--

--[[サキュバス・ソムノ]]--
function matk_magic_succubi_somnophilia(monster)
	local max_range = 20		--特殊攻撃の最大射程

	DEBUG.add_msg("succubi_somnophilia magic-->")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		return
	end

	--ターゲットが既に効果に掛かっている、あるいは寝ているなら何もしない。
	if (target:has_effect(efftype_id("magic_sleepy")) or target:has_effect(efftype_id("sleep"))) then
		DEBUG.add_msg("Welp, slept already.")
		return
	end

	local magic_sleep_cost = 3	--睡眠魔法の実行コスト

	--"spell_charge"のintensityを取得
	local intensity = monster:get_effect_int(efftype_id("spell_charge"))
	DEBUG.add_msg("spell_charge intensity: "..intensity)

	if (intensity >= magic_sleep_cost) then
		DEBUG.add_msg("Let's cast!")
		--intensityが規定値に到達していれば発動！
		magic_sleep(monster, target)
		monster:remove_effect(efftype_id("spell_charge"))

		monster:mod_moves(-500)

	else
		DEBUG.add_msg("Charging...")
		--足りなければ詠唱を続ける
		spell_charge(monster)
		monster:mod_moves(-150)
	end

end

--[[ダークウィッチ]]--
function matk_magic_dark_witch(monster)
	local max_range = 20		--特殊攻撃の最大射程

	DEBUG.add_msg("dark_witch magic-->")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		return
	end

	local magic_fire_cost = 3	--魔法の実行コスト

	--"spell_charge"のintensityを取得
	local intensity = monster:get_effect_int(efftype_id("spell_charge"))
	DEBUG.add_msg("spell_charge intensity: "..intensity)

	if (intensity >= magic_fire_cost) then
		DEBUG.add_msg("Let's cast!")
		--intensityが規定値に到達していれば発動！
		magic_fire_circle(monster, target)
		monster:remove_effect(efftype_id("spell_charge"))

		monster:mod_moves(-300)

	else
		DEBUG.add_msg("Charging...")
		--足りなければ詠唱を続ける
		spell_charge(monster)
		monster:mod_moves(-150)
	end

end


--[[山羊頭の悪魔]]--
function matk_magic_goathead_demon(monster)
	local max_range = 10	--特殊攻撃の最大射程
	local magic_cost = 1	--魔法の実行コスト

	DEBUG.add_msg("goathead_demon magic-->")

	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		return
	end

	--"spell_charge"のintensityを取得
	local intensity = monster:get_effect_int(efftype_id("spell_charge"))
	DEBUG.add_msg("spell_charge intensity: "..intensity)

	if (intensity >= magic_cost) then
		DEBUG.add_msg("Let's cast!")
		--intensityが規定値に到達していれば発動！

		if (game.one_in(4)) then
			--周囲にある魔法陣（召喚）を起動する。
			local locs = get_around_locs(monster:pos(), 0, 10)
			for key, value in pairs(locs) do
				magic_circle_summon(value, MON_ARCH_CUBI_LIST)
			end

		else
			--魔法陣（召喚）を設置する。
			local locate_list = get_around_empty_locs(player:pos())
			magic_write_circle(monster, locate_list[math.random(#locate_list)], "tr_magic_circle_summon")
		end

		monster:remove_effect(efftype_id("spell_charge"))
		monster:mod_moves(-300)

	else
		DEBUG.add_msg("Charging...")
		--足りなければ詠唱を続ける
		spell_charge(monster)
		monster:mod_moves(-150)
	end

end

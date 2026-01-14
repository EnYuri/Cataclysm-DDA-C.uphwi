--[[
	MB_ACT_FLG		메이드씨(쇼고스) 용
		Num ModeName	Active	Desc
		0:일반 모드	보통	지시를 내리지 않은 초기 상태
		1:소극적 모드	소극적	소극적으로, 따라는 오지만 조금 불안정
		2:조명 모드	소극적	조명 모드, 빛나는 소극적 모드. 속도 0인 상태로 움직임이 정지한 상태

	MB_ACT_FLG_L	리틀 메이드 용
		Num ModeName	Active	Desc
		0:일반 모드	보통	지시를 내리지 않은 초기 상태
		1:소극적 모드	소극적	소극적으로, 따라는 오지만 조금 불안정
--]]


function iuse_moonmirror(item, active)
	local t_x, t_y = game.choose_adjacent("누구에게 다이아몬드 손거울을 사용합니까?", player:pos().x, player:pos().y)
	local target = tripoint(t_x, t_y, player:pos().z)
	local crit = g:critter_at(target)
	
	if not crit then
		game.add_msg("거기에는 아무도 없다.")
		return
	end
	
	if crit:is_player() then
		game.add_msg("기분 탓인지 평소보다 더 잘생겨보입니다. 좋은 거울이네요.")
		return
	end
	
	if not crit:is_monster() then
		game.add_msg("아무 의미도 없었다.")
		return
	end
	
	local mob = game.get_monster_at(target)
	local use_flg = false
	
	if mob.type.id == mtype_id("mon_moon_princess") then
		game.popup("<color_white>\"손거울을 찾아와주셨군요! 정말로 감사드려요!\"</color>")
		game.popup("<color_white>\"제가 집으로 돌아가려면 반드시 그 손거울이 필요하답니다.\"</color>")
		game.popup("<color_white>\"마땅한 보답을 할테니 부디 손거울을 돌려주시겠어요?\"</color>")
		game.popup("<color_yellow>고풍스러운 소녀의 눈은 아주 결연한 의지에 차 있다. 손거울이 반드시 필요한 것 같다.</color>")
		local select = game.query_yn("소녀에게 손거울을 건네줍니까? ※거절할 경우 상대방의 분노를 살 수 있습니다")

		if select then
			game.popup("<color_white>\"정말로 뭐라고 감사의 말씀을 드려야할지 모르겠네요. 이 은혜는 거듭 잊지 않겠습니다.\"</color>")
			game.popup("<color_white>\"약소하지만 이건 제 성의의 표시랍니다. 부디 받아주세요.\"</color>")
			
		local menu = game.create_uimenu()
		local choice = -1
		menu.title = "\"둘 중에서 원하는 것을 말씀해보세요.\""
		menu:addentry("더러운 기운으로부터 몸을 보호하고 싶다 (아티팩트 : 체력+2, 방사능 저항)")					--choice 0
		menu:addentry("천재지변에서 안전해지고 싶다 (아티팩트 : 민첩+2, 전기 면역)")						--choice 1
		menu:addentry("벗어.")						--choice 2
		menu:query(true)
		
		choice = menu.selected
		
		if choice == 0 then
			mob:poly(mtype_id("mon_moon_princess_chest"))
			player:i_rem(item)
			return
		elseif choice == 1 then
			mob:poly(mtype_id("mon_moon_princess_chest2"))
			player:i_rem(item)
			return
		elseif choice == 2 then
			local select = game.query_yn("아무리 그래도 그건 미친 짓이 아닐까 싶은데요. 정말로 그렇게 말할 겁니까?")
				if select then
					game.popup("<color_red>\"이 무례한 놈! 은인이라 생각한 이가 이런 불한당일 줄은 몰랐구나!\"</color>")
					mob:poly(mtype_id("mon_moon_princess3"))
					player:i_rem(item)
					else
							menu.title = "\"둘 중에서 원하는 것을 말씀해보세요.\""
							menu:addentry("더러운 기운으로부터 몸을 보호하고 싶다 (아티팩트 : 체력+2, 방사능 저항)")					--choice 0
							menu:addentry("천재지변에서 안전해지고 싶다 (아티팩트 : 민첩+2, 전기 면역)")						--choice 1
							menu:addentry("벗어.")
							menu:query(true)
							choice = menu.selected
									if choice == 0 then
									mob:poly(mtype_id("mon_moon_princess_chest"))
									player:i_rem(item)
									return
									elseif choice == 1 then
									mob:poly(mtype_id("mon_moon_princess_chest2"))
									player:i_rem(item)
									return
									elseif choice == 2 then
									game.popup("<color_yellow>그래요. 정 그렇게 말하고 싶다면 두번은 말리지 않겠습니다.</color>")
									game.popup("<color_red>\"이 무례한 놈! 은인이라 생각한 이가 이런 불한당일 줄은 몰랐구나!\"</color>")
									mob:poly(mtype_id("mon_moon_princess3"))
									player:i_rem(item)
								end
				end
			return
		end
		
		else
			game.popup("<color_yellow>저를 조롱하는 건가요? 그렇게 나오시겠다면 저도 생각이 있습니다!</color>")
			mob:poly(mtype_id("mon_moon_princess2"))
		end
	else
		game.add_msg("의미있는 상대가 아닌 것 같다.")
	end
	
	if use_flg then
		player:i_rem(item)
	end
end




function iuse_dokyak(item, active)
	local t_x, t_y = game.choose_adjacent("자기 자신을 타겟팅하면 초월을 시행합니다.", player:pos().x, player:pos().y)
	local target = tripoint(t_x, t_y, player:pos().z)
	local crit = g:critter_at(target)
	
	
	if not crit then
		game.add_msg("초월을 취소합니다.")

		return
	end
	
	if crit:is_player() then
	
		game.popup("<color_yellow>모든 구름과 천장과 장애물을 넘어 돌연 하늘로부터 눈부신 광휘가 내리쬔다. \n장엄하다 못해 경이마저 느끼게 하는 신성함을 담은 목소리가 울려퍼진다.</color>")
		game.popup("<color_yellow>『헤매이는 어린 양아, 죄 많은 아이야. 너는 내 피로서 그 죄를 사함받았으니, 이제는 내 곁에서 편히 쉬거라.』</color>")
		player:explode()
		game.add_msg("모든 구름과 천장과 장애물을 넘어 돌연 하늘로부터 눈부신 광휘가 내리쬔다. 장엄하다 못해 경이마저 느끼게 하는 신성함을 담은 목소리가 울려퍼진다.")
		game.add_msg("『헤매이는 어린 양아, 죄 많은 아이야. 너는 내 피로서 그 죄를 사함받았으니, 이제는 내 곁에서 편히 쉬거라.』")
		game.add_msg("이 빌어먹을 지옥에서 해방이다!")
		player:i_rem(item)
		
	
		return
	end
	
	if crit:is_monster() then
		game.add_msg("초월을 취소합니다.")
		return
	end
	
	if not crit:is_monster() then
		game.add_msg("초월을 취소합니다.")
		return
	end
	
end


function iuse_keyapo(item, active)
	local t_x, t_y = game.choose_adjacent("누구에게?", player:pos().x, player:pos().y)
	local target = tripoint(t_x, t_y, player:pos().z)
	local crit = g:critter_at(target)
	
	if not crit then
		game.add_msg("거기에는 아무도 없다.")
		return
	end
	
	if crit:is_player() then
		game.add_msg("어디다 꽂으려고?")
		return
	end
	
	if not crit:is_monster() then
		game.add_msg("아무 의미도 없었다.")
		return
	end
	
	local mob = game.get_monster_at(target)
	local use_flg = false
	
	if mob.type.id == mtype_id("mon_door_angel") then
		game.popup("<color_yellow>문지기는 무저갱 상층 열쇠를 보고 고개를 끄덕인다.</color>")
		local select = game.query_yn("무저갱 상층의 문을 엽니까?")

		if select then
			game.popup("<color_yellow>문지기는 다시 한번 고개를 끄덕였다.</color>")
			game.popup("<color_yellow>무저갱 상층으로 들어갈 수 있게 되었다. 준비를 단단히 해야 할 것이다.</color>")
			mob:poly(mtype_id("mon_door_angel_compromised"))
		else
			game.popup("<color_yellow>문지기는 아무 응답도 없다.</color>")
		end
	else
		game.add_msg("의미있는 상대가 아닌 것 같다.")
	end
	
	if use_flg then
		player:i_rem(item)
	end
end


function iuse_keyapo2(item, active)
	local t_x, t_y = game.choose_adjacent("누구에게?", player:pos().x, player:pos().y)
	local target = tripoint(t_x, t_y, player:pos().z)
	local crit = g:critter_at(target)
	
	if not crit then
		game.add_msg("거기에는 아무도 없다.")
		return
	end
	
	if crit:is_player() then
		game.add_msg("어디다 꽂으려고?")
		return
	end
	
	if not crit:is_monster() then
		game.add_msg("아무 의미도 없었다.")
		return
	end
	
	local mob = game.get_monster_at(target)
	local use_flg = false
	
	if mob.type.id == mtype_id("mon_extra_sealed") then
		game.popup("<color_yellow>이 밑에서 거대한 존재감이 느껴진다...</color>")
		local select = game.query_yn("무저갱 하층의 봉인을 해제합니까?")

		if select then
			game.popup("<color_yellow>봉인이 해제되었고, 보통의 문이 되었다.</color>")
			game.popup("<color_yellow>파멸이 저 아래에서 당신을 기다린다.</color>")
			mob:poly(mtype_id("mon_extra_sealed_compromised"))
		else
			game.popup("<color_yellow>현명한 선택이다.</color>")
		end
	else
		game.add_msg("의미있는 상대가 아닌 것 같다.")
	end
	
	if use_flg then
		player:i_rem(item)
	end
end

game.register_iuse("IUSE_MOONMIRROR", iuse_moonmirror)
game.register_iuse("IUSE_DOKYAK", iuse_dokyak)
game.register_iuse("IUSE_KEYAPO", iuse_keyapo)
game.register_iuse("IUSE_KEYAPO2", iuse_keyapo2)

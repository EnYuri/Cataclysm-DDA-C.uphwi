--[[定数]]--


--[[文字のハイライト色パターン]]--
H_COLOR = {
	BLACK		= "black",
	WHITE		= "white",
	LIGHT_GRAY	= "light_gray",
	DARK_GRAY	= "dark_gray",
	RED			= "red",
	GREEN		= "green",
	BLUE		= "blue",
	CYAN		= "cyan",
	MAGENTA		= "magenta",
	BROWN		= "brown",
	LIGHT_RED	= "light_red",
	LIGHT_GREEN	= "light_green",
	LIGHT_BLUE	= "light_blue",
	LIGHT_CYAN	= "light_cyan",
	PINK		= "pink",
	YELLOW		= "yellow"
}

--[[*気持ちいいこと*中に表示されるテキスト]]--
MOVINGDOING_TEXTS = {
	"*쥬퓹쥬븝*",
	"*즈펍즈펍*",
	"『하아하아』",
	"『들려버려엇』",
	"『으읏♡』",
	"『오옥♡』",
	"『우후후♪』",
	"『아앗♪』"
}
--todo: perhaps move these dialog lines out of const into json so we could randomize words and add gender-specific and etc checks?
--another problem is that you can still hear this even when deaf
--[[レイダー的な敵キャラ会話のテキスト]]--
VULGAR_SPEECH_TEXTS = {
	--ターゲットを発見した時
	TARGET_ACQUIRE = {
		--[[露骨なパロディネタはいちおう自粛。
			"\"地獄だ、やあ！\"",
		]]--
		"\"아하!\"",
		"\"아-하!!\"",
		"\"가까이 와봐!\"",
		"\"무슨-?!\"",
		"\"야, 저건 적이야!!\"",
		"\"교전한다!\"",
		"\"적이야!!\"",
		"\"하, 이제 네가 보이네!\"",
		"\"햐햣-!\"",
		"\"네 모가지를 비틀어 따버린다음 내 크리스마스 장식으로 간직해주지!\"",
		"\"아, 신선한 노예!\"",
		"\"아, 신선한 고기!!\"",
		"\"오늘 밤은 인육 바베큐다!!\"",
		"\"강간.. 강가아아아아아아안-!!\"",
		"(미치광이 웃음)",
		"\"씨발, 이거지!!\"",
		"\"넌 존나 뒤졌어, 알아들어? 뒤졌다고!!\""
		--"\"地獄だ、イェア！\""
	},
	--ターゲットと交戦中
	TARGET_ENGAGE = {
		--[[露骨なパロディネタはいちおう自粛。
			"\"殺しは初めてじゃないんだよ、新米！\"",
			"\"何百回とやってきた！そうすれば変わるだろう！？\"",
			"\"自分を制して、悪に徹しろ！\"",
		]]--
		"\"핫-하!\"",
		"\"쫄았니, 응?!\"",
		"\"숨지마 보지년아!!\"",
		"\"피, 피!! 피이이이이이이!!!!\"",
		"\"존나게 큰 젖탱이, 피도 존나게 흘리겠지!!!\"",
		"\"넌 씨발 좆도 아니야아아아아아아아아아아아!!!\"",
		"\"닌 나한테 좆도 안돼!!\"",
		"\"죽이고 범한다? 범하고 죽인다? 둘다 조지는 아이디어인데!\"",
		"\"널 씨발 강간한다음에, 죽이고, 다시 강간할꺼야, 알아 들어 씹년아?!\"",
		"\"살인! 약탈! 방화! 강간!!!\"",
		"\"널 도와줄 생각은 없지만서도, 혹시 몰라? 널 가지고 논다음엔 그런 맘이 들지도?!\"",
		"(미치광이 웃음)",
		"(울부짖음)",
		"(길게 울무짖음)",
		"(으르렁댐)",
		"\"뒤져어어어어어어!!!\"",
		"\"널 씨발 조져버릴꺼야!\"",
		"\"난 그냥 질펀하게 놀고 싶을 뿐이라고, 상관없지, 그치??\"",
		"\"이 씨발 존만한 새끼가..\"",
		"\"왜 씨발 아직도 안뒤진거야!!\"",
		"\"왜 죽질 않는거야, 왜!!\"",
		"\"내가 사람 담구는건 이게 처음이 아니라고, 좆만아!\"",
		"\"내가 사람새끼로 살수 없다면, 악마새끼로는 살 수 있을지도 모르지!\"",
		"\"지옥에 떨어지면 내가 보냈다고 해라!\"",
		"\"너가 죽으면 그 시체를 강간하고.. 야, 걱정하지마, 상냥하게 할테니까!\"",
		"\"나한테 씨발 울고불며 빌게 될꺼다!\""
	},
	--ターゲットを見失った時
	TARGET_LOST = {
		"(혀를 차는 소리)",
		"\"그래. 뒤지게 튀어야겠지.\"",
		"\"그새끼 존나 빠르네.\"",
		"\"나와, 나와!! 씹년아!, 빨리 끝내줄테니까!\"",
		"\"그만 쳐 숨고 나와 이새끼야!!\"",
		"\"조심해, 그 씹새가 아직 어디 숨어있다고..\"",
		"\"작작 도망쳐!!\"",
		"\"아...!! 이새끼 어디갔어!!\"",
		"\"하, 이제 네가 보이네! 아니. 안보여, 아니, 이제 보이-씨발!!!\"",
		"\"겁대가리만 들어찬 개씹보지년이!!!\""
	}
}

--[[profession"一人と一匹"スタート時のペット選択リストまとめ]]--
PROF_PET_LIST = {
	TITLE = "당신의 펫은...",
	LIST_ITEM = {
		{
			ENTRY = "개다！",
			PET_ID = "mon_dog",
			BONUS_ITEM = {"pet_carrier", "dog_whistle"}
		},
		{
			ENTRY = "고양이다！",
			PET_ID = "mon_cat",
			BONUS_ITEM = {"pet_carrier", "can_tuna"}
		},
		{
			ENTRY = "곰이다！",
			PET_ID = "mon_bear_cub",
			BONUS_ITEM = {}
		},
		{
			ENTRY = "몽마다！",
			PET_ID = "mon_succubi",
			BONUS_ITEM = {"holy_choker"}
		}
	}
}

--[[アークCUBIのmonster_idリスト。主に上位敵の召喚用に使う。]]--
MON_ARCH_CUBI_LIST = {
	"mon_succubi_sadist",
	"mon_succubi_somnophilia",
	"mon_succubi_exhibitionism",
	"mon_succubi_lactophilia",
	"mon_incubi_sthenolagnia",
	"mon_incubi_phalloplas",
	"mon_incubi_hoplophilia"
}

SEX_MORALE_TYPE		= morale_type("morale_sex_good")	--*気持ちいいこと*の意欲タイプ
SEX_BASE_TURN		= 100		--行為1wait当たりに掛かる基準ターン数(1ターン = 約6秒)。100=10分。
SEX_MAX_TURN		= 1800		--行為全体に掛かる最大ターン数。1800=3時間。
SEX_FUN_DURATION	= 600		--行為による意欲がどの程度長続きするかのtime_duration。
SEX_FUN_DECAY_START	= 150		--行為による意欲が冷め始めるまでのtime_duration。

D_GOM_BREAK_CHANCE	= 50		--あぶない方の避妊具が使用時に破損する確率(%)。

PREG_CHANCE = 10				--基礎妊娠確立(%)。
DEFAULT_PREG_SPEED_RATIO = 1	--孕んだ子供の成長スピード比率。


DEFAULT_NPC_NAME = "에마님"		--NPC新規生成時のデフォルト名。みんな大好きトム。


EFF_SPELL_CHARGE_INT_FACTOR = 30	--モンスター攻撃の魔法詠唱にかかるint_dur_factor。


--[[set_valueの値設定に使う名称]]--
EVENT_GOATHEAD_DEMON = "event_goathead_demon"				--モンスター"mon_goathead_demon"との会話イベントを発生させたかどうか
EVENT_DEMONBEING_SCHOOLGIRL = "event_demonbeing_schoolgirl"	--npc"demonbeing_schoolgirl"を発生させたかどうか
CREAMPIE_SEED_TYPE = "creampie_seed_type"					--注がれた種の種族を保持する。あなたがパパになるんですよ？

#include "hentai_sp.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <vector>

#include "avatar.h"
#include "bodypart.h"
#include "calendar.h"
#include "character.h"
#include "character_effects.h"
#include "creature.h"
#include "effect.h"
#include "enums.h"
#include "game.h"
#include "item.h"
#include "map/map.h"
#include "messages.h"
#include "monster.h"
#include "mtype.h"
#include "npc.h"
#include "output.h"
#include "rng.h"
#include "string_formatter.h"
#include "translations.h"
#include "type_id.h"
#include "ui.h"

namespace
{
const species_id species_FEMALE( "FEMALE" );
const species_id species_MALE( "MALE" );
const species_id species_HERM( "HERM" );
const species_id species_CUBI( "CUBI" );

const efftype_id effect_corrupt( "corrupt" );
const efftype_id effect_estrus( "estrus" );
const efftype_id effect_female_estrus( "female_estrus" );
const efftype_id effect_contraception( "contraception" );
const efftype_id effect_lust( "lust" );
const efftype_id effect_webbed( "webbed" );
const efftype_id effect_beartrap( "beartrap" );
const efftype_id effect_crushed( "crushed" );
const efftype_id effect_grabbed( "grabbed" );
const efftype_id effect_in_pit( "in_pit" );
const efftype_id effect_sleep( "sleep" );
const efftype_id effect_zapped( "zapped" );

const efftype_id effect_drunk( "drunk" );
const efftype_id effect_movingdoing( "movingdoing" );
const efftype_id effect_impregnated( "impregnated" );
const efftype_id effect_creampie( "creampie" );

const morale_type morale_orgasm( "morale_orgasm" );
const morale_type morale_deflower_good( "morale_deflower_good" );
const morale_type morale_deflower_bad( "morale_deflower_bad" );
const morale_type morale_sex_good( "morale_sex_good" );

const efftype_id effect_pregnantcy( "pregnantcy" );
const efftype_id effect_gotwifed( "gotwifed" );

const trait_id trait_VIRGIN( "VIRGIN" );
const trait_id trait_ESTRUS_MAID( "ESTRUS_MAID" );
const trait_id trait_ESTRUS_MAID_WEAK( "ESTRUS_MAID_WEAK" );
const trait_id trait_ESTRUS_LUPINE( "ESTRUS_LUPINE" );
const trait_id trait_ESTRUS_FELINE( "ESTRUS_FELINE" );

const activity_id ACT_SEX( "ACT_SEX" );

// const.lua MOVINGDOING_TEXTS
const std::vector<std::string> movingdoing_texts = {
    translate_marker( "*쥬퓹쥬븝*" ), translate_marker( "*즈펍즈펍*" ),
    translate_marker( "『하아하아』" ), translate_marker( "『들려버려엇』" ),
    translate_marker( "『으읏♡』" ), translate_marker( "『오옥♡』" ),
    translate_marker( "『우후후♪』" ), translate_marker( "『아앗♪』" )
};

// const.lua sex timing constants
const auto SEX_BASE_DURATION = 10_minutes;
const auto SEX_MAX_DURATION = 3_hours;
const auto SEX_FUN_DURATION = 1_hours;
const auto SEX_FUN_DECAY_START = 15_minutes;
const int D_GOM_BREAK_CHANCE = 50;

const bodypart_str_id hsp_bp_leg_l( "leg_l" );
const bodypart_str_id hsp_bp_leg_r( "leg_r" );

// monattack.lua: lewd sentence fragments, concatenated at runtime.
const std::vector<std::string> body_part_texts = {
    translate_marker( "뺨" ), translate_marker( "입술" ), translate_marker( "귀" ),
    translate_marker( "손가락" ), translate_marker( "손" ), translate_marker( "팔" ),
    translate_marker( "가슴" ), translate_marker( "하복부" ), translate_marker( "고간" ),
    translate_marker( "음부" ), translate_marker( "엉덩이" ), translate_marker( "허벅지" ),
    translate_marker( "다리" )
};

const std::vector<std::string> action_texts = {
    translate_marker( "을(를) 어뤄만졌다." ), translate_marker( "을(를) 쓰다듬어 올렸다." ),
    translate_marker( "을(를) 부드럽게 주물렀다." ), translate_marker( "을(를) 간드러지게 쓸어내렸다." ),
    translate_marker( "을(를) 가볍게 쥐었다." ), translate_marker( "을(를) 문질러 자극했다." ),
    translate_marker( "을(를) 농락했다." ), translate_marker( "에 키스했다." ),
    translate_marker( "을(를) 혀로 핥았다." ), translate_marker( "을(를) 핥아 올렸다." ),
    translate_marker( "을(를) 빨았다." ), translate_marker( "에 뜨거운 한숨을 내뱉었다." )
};

const std::vector<std::string> hip_action_texts = {
    translate_marker( "푹푹 쑤셨다." ), translate_marker( "피스톤질 했다." ),
    translate_marker( "마구 휘저었다." ), translate_marker( "팡팡 부딪혔다." ),
    translate_marker( "움직였다." ), translate_marker( "위아래로 흔들었다." ),
    translate_marker( "앞뒤로 흔들었다." ), translate_marker( "규칙적으로 박아댔다." )
};
} // namespace

namespace hentai
{

bool get_gender( const Creature &c )
{
    if( const monster *z = c.as_monster() ) {
        const mtype &mt = *z->type;
        if( mt.in_species( species_FEMALE ) ) {
            return false;
        }
        if( mt.in_species( species_MALE ) ) {
            return true;
        }
        if( mt.in_species( species_HERM ) ) {
            return false; // count herms/futas as females, matching the Lua
        }
        return true; // other monsters default to male
    }
    if( const Character *ch = c.as_character() ) {
        return ch->male;
    }
    return true;
}

std::string pro( const Creature &c, const std::string &pronoun )
{
    const bool is_pc = c.is_avatar();
    const bool male = get_gender( c );
    if( pronoun == "he" ) {
        return is_pc ? "you" : ( male ? "he" : "she" );
    }
    if( pronoun == "his" ) {
        return is_pc ? "your" : ( male ? "his" : "her" );
    }
    if( pronoun == "him" ) {
        return is_pc ? "you" : ( male ? "him" : "her" );
    }
    if( pronoun == "hers" ) {
        return is_pc ? "yours" : ( male ? "his" : "hers" );
    }
    if( pronoun == "himself" ) {
        return is_pc ? "yourself" : ( male ? "himself" : "herself" );
    }
    return "*Pronoun error!*";
}

std::string you_word( const Creature &c, const std::string &you_w, const std::string &them_w )
{
    return c.is_avatar() ? you_w : them_w;
}

std::string actor_name( const Creature &c, const std::string &you_w, const std::string &them_w_in )
{
    const std::string them_w = them_w_in.empty() ? you_w : them_w_in;
    const std::string out = c.disp_name();
    const std::string word = you_word( c, you_w, them_w );

    if( you_w == "'s" ) { // special case from translation.lua
        if( c.is_avatar() ) {
            return "your";
        }
        return out + word;
    }
    return out + " " + word;
}

bool is_cubi( const monster &z )
{
    return z.type->in_species( species_CUBI );
}

std::string random_body_part()
{
    return _( random_entry( body_part_texts ) );
}

std::string random_action()
{
    return _( random_entry( action_texts ) );
}

std::string random_hip_action()
{
    return _( random_entry( hip_action_texts ) );
}

std::vector<tripoint_bub_ms> love_formula( const tripoint_bub_ms &center, int radius,
        double curvature )
{
    std::vector<tripoint_bub_ms> out;
    if( radius <= 0 ) {
        return out;
    }
    const double b = curvature;
    const double dx = 1.0 / radius * 2.0;

    const auto emit = [&]( double x, double y ) {
        const int rx = static_cast<int>( std::lround( x * radius ) );
        const int ry = static_cast<int>( std::lround( y * radius * -1.0 ) );
        out.emplace_back( center.x() + rx, center.y() + ry, center.z() );
        out.emplace_back( center.x() - rx, center.y() + ry, center.z() );
    };

    for( double x = 0.0; x <= 1.0; x += dx ) {
        emit( x, std::sqrt( 1.0 - x * x ) + b * std::sqrt( x ) );
    }
    for( double x = 1.0; x >= 0.0; x -= dx ) {
        emit( x, -std::sqrt( 1.0 - x * x ) + b * std::sqrt( x ) );
    }
    return out;
}

std::vector<tripoint_bub_ms> around_empty_locs( const tripoint_bub_ms &center )
{
    std::vector<tripoint_bub_ms> locs;
    for( int dx = -1; dx <= 1; dx++ ) {
        for( int dy = -1; dy <= 1; dy++ ) {
            const tripoint_bub_ms p( center.x() + dx, center.y() + dy, center.z() );
            if( g->is_empty( p ) ) {
                locs.push_back( p );
            }
        }
    }
    return locs;
}

std::vector<tripoint_bub_ms> around_locs( const tripoint_bub_ms &center, int min_radius,
        int max_radius )
{
    std::vector<tripoint_bub_ms> locs;
    for( int dx = -max_radius; dx <= max_radius; dx++ ) {
        for( int dy = -max_radius; dy <= max_radius; dy++ ) {
            if( std::max( std::abs( dx ), std::abs( dy ) ) < min_radius ) {
                continue;
            }
            locs.emplace_back( center.x() + dx, center.y() + dy, center.z() );
        }
    }
    return locs;
}

void add_permanent_effect( Creature &target, const efftype_id &eff, const time_duration &dur )
{
    target.add_effect( eff, dur );
    if( target.has_effect( eff ) ) {
        target.get_effect( eff ).set_permanent();
    }
}

void reduce_counter_effect( Creature &target, const efftype_id &eff )
{
    if( !target.has_effect( eff ) ) {
        return;
    }
    effect &e = target.get_effect( eff );
    if( e.get_duration() <= 1_turns ) {
        target.remove_effect( eff );
    } else {
        e.mod_duration( -1_turns );
    }
}

void gain_corrupt( Creature &target, int dur_turns )
{
    const Character *ch = target.as_character();
    const int int_cur = ch ? ch->int_cur : 8;

    if( rng( 1, 20 ) > int_cur ) {
        // Callers retain the original six-second-turn amounts from the Lua port.
        target.add_effect( effect_corrupt, time_duration::from_seconds( dur_turns * 6 ) );
        if( target.is_avatar() ) {
            add_msg( m_bad, _( "당신은 하복부로부터 뜨거운 욕정이 타고 오르는 것을 느꼈다!" ) );
        }
    } else {
        add_msg( string_format( _( "하지만... %s은(는) 욕정을 인내력으로 억눌렀다!" ),
                                target.disp_name() ) );
    }
}

detached_ptr<item> ejaculate_item( const Creature &c )
{
    const itype_id id = c.is_monster() ? itype_id( "d_cum" ) : itype_id( "h_semen" );
    detached_ptr<item> liquid = item::spawn( id, calendar::turn, 1 );
    if( liquid ) {
        liquid->set_relative_rot( 0 ); // freshly produced
    }
    return liquid;
}

bool preg_roll( Character &mother )
{
    // Basis points preserve fractional percentages after contraception.
    int preg_chance = 1000; // 10 percent
    if( mother.has_effect( effect_female_estrus ) ) {
        preg_chance *= 20;
    } else if( mother.has_effect( effect_estrus ) ) {
        preg_chance *= 5;
    }
    if( mother.has_effect( effect_contraception ) ) {
        preg_chance /= 100;
    }
    return rng( 1, 10000 ) <= preg_chance;
}

bool is_naked( const Character &c )
{
    return c.worn.empty();
}

item *get_random_wear( Character &c )
{
    std::vector<item *> worn_items;
    for( item *const it : c.worn ) {
        worn_items.push_back( it );
    }
    if( worn_items.empty() ) {
        return nullptr;
    }
    return random_entry( worn_items );
}

bool has_cum( Creature &c )
{
    const int intensity = c.get_effect_int( effect_lust );
    if( intensity < 100 ) {
        return false;
    }
    add_msg( m_good, string_format( _( "%s은(는) 절정했다!" ), c.disp_name() ) );
    c.remove_effect( effect_lust );
    if( Character *ch = c.as_character() ) {
        ch->add_morale( morale_orgasm, rng( 1, 3 ), 0, 1_hours, 10_minutes );
    }
    c.mod_moves( -50 );
    return true;
}

bool can_wife( monster &z, Character &target )
{
    // The lower body must be exposed.
    if( target.wearing_something_on( hsp_bp_leg_l.id() ) &&
        target.wearing_something_on( hsp_bp_leg_r.id() ) ) {
        if( one_in( 5 ) ) {
            add_msg( m_warning, string_format( _( "%s은(는) 당신의 비부를 노리고 있다...!" ),
                                               z.disp_name() ) );
        }
        return false;
    }
    // Otherwise it only works if the target cannot move.
    static const std::vector<efftype_id> immobile = {
        effect_webbed, effect_beartrap, effect_crushed, effect_grabbed,
        effect_in_pit, effect_sleep, effect_zapped
    };
    for( const efftype_id &e : immobile ) {
        if( target.has_effect( e ) ) {
            return true;
        }
    }
    return false;
}

namespace
{
void deflower_pain( Character &me, bool is_good )
{
    if( get_gender( me ) ) { // currently female-only, matching the Lua
        return;
    }
    int deal_pain = 0;
    if( is_good ) {
        deal_pain = 5;
        if( me.is_avatar() ) {
            add_msg( m_good, _( "..그렇게 아프진 않았다." ) );
        } else {
            add_msg( string_format( _( "%s은(는) 불편한듯 몸을 조금 비틀었다.." ), me.disp_name() ) );
        }
    } else {
        deal_pain = 15;
        if( me.is_avatar() ) {
            add_msg( m_bad, _( "아파.. 아파...!!" ) );
        } else {
            add_msg( string_format( _( "%s은(는) 상실의 격통에 몸을 비틀었다!" ), me.disp_name() ) );
        }
    }
    me.mod_pain( deal_pain );
}
} // namespace

void lost_virgin( Character &me, bool is_good )
{
    if( !me.has_trait( trait_VIRGIN ) ) {
        return;
    }
    if( is_good ) {
        add_msg( m_good, string_format( _( "%s는(은) 순결을 잃었다!" ), me.disp_name() ) );
        me.add_morale( morale_deflower_good, 20, 0, 3_days, 12_hours );
    } else {
        add_msg( m_bad, string_format( _( "%s는(은) 순결이 더럽혀졌다!" ), me.disp_name() ) );
        me.add_morale( morale_deflower_bad, -20, 0, 3_days, 12_hours );
    }
    deflower_pain( me, is_good );
    me.unset_mutation( trait_VIRGIN );
}

std::string seduce_message( const Creature &mon, const Character &target )
{
    const std::string mon_name = mon.disp_name();
    const std::string tname = target.disp_name();
    const std::string &bp_raw = random_entry( body_part_texts );
    const std::string &act_raw = random_entry( action_texts );
    const std::string bp = _( bp_raw );
    const std::string act = _( act_raw );

    if( bp_raw == "가슴" && one_in( 5 ) ) {
        return string_format( _( "%1$s은(는) %2$s 의 가슴을 애무했다." ), mon_name, tname );
    }
    if( bp_raw == "귀" && one_in( 5 ) ) {
        return string_format( _( "%1$s은(는) %2$s 의 귀를 살짝 빨아 물었다." ), mon_name, tname );
    }
    if( bp_raw == "손" && one_in( 5 ) ) {
        return string_format( _( "%1$s은(는) %2$s 의 손을 꼭 쥐었다." ), mon_name, tname );
    }
    if( act_raw == "에 키스했다." ) {
        if( bp_raw == "입술" ) {
            const std::string his = pro( mon, "his" );
            if( target.has_trait( trait_id( "FORKED_TONGUE" ) ) ) {
                return string_format(
                           _( "%1$s joins %2$s lips with %3$s's, forcing %4$s tongue inside %5$s mouth and enjoying the feel of %6$s's unusually forked tongue while tasting each other's saliva" ),
                           mon_name, his, tname, his, pro( target, "his" ), tname );
            }
            return string_format(
                       _( "%1$s joins %2$s lips with %3$s's, forcing %4$s tongue inside %5$s mouth and entwining %6$s tongues together while tasting each other's saliva" ),
                       mon_name, his, tname, his, pro( target, "his" ), you_word( target, "your", "their" ) );
        }
        return string_format( _( "%1$s은(는) %2$s의 %3$s%4$s" ), mon_name, tname, bp, act );
    }
    if( one_in( 5 ) ) {
        if( target.has_trait( trait_id( "TAIL_FLUFFY" ) ) && one_in( 5 ) ) {
            return string_format( _( "%1$s은(는) %2$s 의 부드러운 솜털 꼬리를 어루만졌다." ), mon_name, tname );
        }
        if( target.has_trait( trait_id( "TAIL_FIEND" ) ) && one_in( 5 ) ) {
            return string_format( _( "%1$s은(는) %2$s 의 악마 꼬리를 부드럽게 꼬아 문질렀다." ), mon_name, tname );
        }
        if( target.has_trait( trait_id( "TAIL" ) ) && one_in( 5 ) ) {
            return string_format( _( "%1$s은(는) %2$s 의 꼬리를 쓸어내렸다." ), mon_name, tname );
        }
        if( target.has_trait( trait_id( "WINGS" ) ) && one_in( 5 ) ) {
            return string_format( _( "%1$s은(는) %2$s 의 날개를 부드럽게 만질거렸다." ), mon_name, tname );
        }
        return string_format( _( "%1$s은(는) %2$s 의 머리를 도담도담 쓰다듬었다." ), mon_name, tname );
    }
    if( one_in( 5 ) ) {
        return string_format( _( "%1$s은(는) %2$s 의 머리카락을 빗어 내렸다." ), mon_name, tname );
    }
    return string_format( _( "%1$s은(는) %2$s의 %3$s %4$s" ), mon_name, tname, bp, act );
}

int get_willing( const npc &partner, bool &is_love )
{
    is_love = false;
    if( partner.is_enemy() ) {
        return -999;
    }
    double trust = character_effects::talk_skill( get_avatar() );
    double fear = character_effects::intimidation( get_avatar() );
    const npc_opinion &op = partner.op_of_u;
    trust += op.trust * 2 + op.value - op.anger / 2.0;
    fear += op.fear * 2 + op.owed / 2.0;
    if( partner.has_effect( effect_drunk ) ) {
        trust *= 1.2;
        fear *= 0.8;
    }
    if( partner.has_effect( effect_estrus ) ) {
        trust *= 3.0;
        fear /= 3.0;
    }
    if( partner.has_effect( effect_female_estrus ) ) {
        trust *= 12.0;
        fear /= 12.0;
    }
    double willing;
    if( trust >= fear ) {
        willing = trust;
        is_love = true;
    } else {
        willing = fear;
        is_love = false;
    }
    if( partner.has_effect( effect_corrupt ) ) {
        willing += partner.get_effect_int( effect_corrupt ) * 5;
    }
    if( partner.has_trait( trait_VIRGIN ) ) {
        willing -= 30;
    }
    return static_cast<int>( willing );
}

bool is_accept_u( npc &partner, itype_id &device, bool &is_love )
{
    const int willing = get_willing( partner, is_love );
    if( willing > 50 ) {
        if( is_love ) {
            popup( "%s", _( "기뻐하면서 내 말을 따라줬다." ) );
            partner.say( ( partner.is_following() || partner.is_player_ally() )
                         ? "<fun_stuff_accept>" : "<fun_stuff_accept_wanderer>" );
            if( rng( 1, 100 ) <= willing &&
                query_yn( string_format(
                              _( "%s은(는) 피임도구를 쓰지 않고 즐기고 싶은 듯 합니다. 쓰지않고 하겠습니까?" ),
                              partner.get_name() ) ) ) {
                device = itype_id::NULL_ID();
                partner.say( "<fun_stuff_raw>" );
            }
        } else {
            popup( string_format( _( "%s당신에 대한 강렬한 공포감 때문에 완전히 복종하고 있다..." ),
                                  partner.get_name() ) );
            partner.say( "<fun_stuff_fear>" );
        }
        return true;
    }
    if( willing > 25 ) {
        if( is_love ) {
            popup( "%s", _( "조금 부끄러워하면서 내 말을 따라줬다." ) );
            partner.say( "<fun_stuff_shy>" );
        } else {
            popup( string_format( _( "%s당신에게 품은 두려움 떄문에 거부할 수 없었다..." ),
                                  partner.get_name() ) );
            partner.say( "<fun_stuff_fear>" );
        }
        return true;
    }
    if( willing > 0 ) {
        popup( "%s", _( "넌지시 거절했다." ) );
        partner.say( "<fun_stuff_refuse>" );
    } else {
        popup( "%s", _( "대놓고 거부했다." ) );
        partner.say( "<fun_stuff_refuse_rough>" );
    }
    return false;
}

void start_sex( avatar &p, npc *partner, const itype_id &device, bool is_love )
{
    int turn_cost = to_turns<int>( SEX_BASE_DURATION ) * p.str_cur;
    if( turn_cost > to_turns<int>( SEX_MAX_DURATION ) ) {
        turn_cost = to_turns<int>( SEX_MAX_DURATION );
    }
    int fun_base = p.dex_cur;
    if( partner && partner->dex_cur > fun_base ) {
        fun_base = partner->dex_cur;
    }
    const int sex_fun_bonus = static_cast<int>( fun_base * 1.2 );

    p.set_value( "hsp_sex_fun", std::to_string( sex_fun_bonus ) );
    p.set_value( "hsp_sex_love", is_love ? "1" : "0" );
    p.set_value( "hsp_sex_device", device.is_null() ? "" : device.str() );
    p.set_value( "hsp_sex_partner",
                 partner ? std::to_string( partner->getID().get_value() ) : "-1" );

    const int turn_hold = turn_cost * p.get_speed() + 6000;
    p.assign_activity( ACT_SEX, turn_hold, 0, 0, "" );
    if( partner ) {
        partner->mod_moves( -turn_hold );
        lost_virgin( p, true );
        lost_virgin( *partner, is_love );
    }
    add_msg( "<color_pink>%s</color>", _( "*잠깐만 기다려줘요*" ) );
}

void sex_do_turn( player &p )
{
    if( !calendar::once_every( SEX_BASE_DURATION ) ) {
        return;
    }
    const int fun = std::max( 0, std::atoi( p.get_value( "hsp_sex_fun" ).c_str() ) );
    const bool is_love = p.get_value( "hsp_sex_love" ) == "1";

    add_msg( "%s", _( random_entry( movingdoing_texts ) ) );
    p.add_morale( morale_sex_good, fun, 0, SEX_FUN_DURATION, SEX_FUN_DECAY_START );
    p.add_effect( effect_movingdoing, SEX_BASE_DURATION );

    const int pid = std::atoi( p.get_value( "hsp_sex_partner" ).c_str() );
    if( pid >= 0 ) {
        if( npc *const partner = g->find_npc( character_id( pid ) ) ) {
            partner->add_effect( effect_movingdoing, SEX_BASE_DURATION );
            if( is_love ) {
                partner->add_morale( morale_sex_good, fun, 0,
                                     SEX_FUN_DURATION, SEX_FUN_DECAY_START );
            }
        }
    }
}

void sex_finish( player &p )
{
    add_msg( _( "*기분 좋은 일*을 끝마쳤다." ) );
    p.remove_effect( effect_lust );
    p.remove_effect( effect_movingdoing );
    if( p.has_effect( effect_female_estrus ) ) {
        add_msg( m_good, string_format( _( "%s의 발정이 잠시 해소되었다." ), p.disp_name() ) );
        p.remove_effect( effect_female_estrus );
    }

    npc *partner = nullptr;
    const int pid = std::atoi( p.get_value( "hsp_sex_partner" ).c_str() );
    if( pid >= 0 ) {
        partner = g->find_npc( character_id( pid ) );
    }
    const bool is_love = p.get_value( "hsp_sex_love" ) == "1";
    const std::string dev_str = p.get_value( "hsp_sex_device" );
    const bool has_device = !dev_str.empty();
    const itype_id device_id( has_device ? dev_str : std::string( "null" ) );

    if( partner ) {
        partner->remove_effect( effect_lust );
        partner->remove_effect( effect_movingdoing );
        npc_opinion &op = partner->op_of_u;
        if( is_love ) {
            op.trust += 2;
            op.value += 2;
            op.fear -= 1;
            op.anger -= 1;
            partner->say( ( partner->is_following() || partner->is_player_ally() )
                          ? "<fun_stuff_love>" : "<fun_stuff_bye>" );
        } else {
            op.fear += 5;
            op.anger += 1;
            op.trust -= 2;
            op.owed -= 1;
            partner->say( "<fun_stuff_bye_fear>" );
        }
    }

    // Find the real device item in the player's inventory.
    item *device = nullptr;
    if( has_device ) {
        for( item *const it : p.items_with( [&]( const item & i ) {
        return i.typeId() == device_id;
        } ) ) {
            device = it;
            break;
        }
    }
    if( device != nullptr && device->typeId() == itype_id( "condom_danger" ) &&
        rng( 1, 100 ) <= D_GOM_BREAK_CHANCE ) {
        add_msg( m_bad, _( "콘돔이 찢어져버렸다!" ) );
        device->detach();
        device = nullptr;
    }

    detached_ptr<item> semen = item::spawn( itype_id( "h_semen" ), calendar::turn, 1 );
    if( semen ) {
        semen->set_relative_rot( 0 );
    }

    if( device != nullptr ) {
        const bool female_pair = ( partner == nullptr ) ||
                                 ( !get_gender( p ) && !get_gender( *partner ) );
        if( female_pair ) {
            popup( "%s", _( "사용한 피임 도구를 버렸다." ) );
        } else {
            Character &finisher = p.male ? static_cast<Character &>( p )
                                  : static_cast<Character &>( *partner );
            popup( string_format( _( "%s은(는) 콘돔 안에 사정했다!" ), finisher.disp_name() ) );
        }
        device->detach();
        detached_ptr<item> used = item::spawn( itype_id( "used_condom" ), calendar::turn, 1 );
        used->fill_with( std::move( semen ) );
        p.i_add( std::move( used ) );
    } else {
        g->m.add_item_or_charges( p.bub_pos(), std::move( semen ) );
        if( partner ) {
            const auto check_preg = []( Character & mother, Character & father ) {
                if( mother.male || !father.male ) {
                    return;
                }
                popup( string_format( _( "%1$s은(는) %2$s에게 질내사정 했다!" ),
                                      father.disp_name(), mother.disp_name() ) );
                mother.set_value( "creampie_seed_type", "HUMAN" );
                if( preg_roll( mother ) ) {
                    add_permanent_effect( mother, effect_impregnated, 1_turns );
                } else {
                    mother.add_effect( effect_creampie, 5_days );
                }
            };
            check_preg( p, *partner );
            check_preg( *partner, p );
            partner->set_moves( 0 );
        }
    }

    p.set_value( "hsp_sex_partner", "-1" );
    p.set_value( "hsp_sex_device", "" );
}

namespace
{
// main.lua preg_process: estrus by trait + impregnated -> pregnantcy.
void preg_process( Character &mother )
{
    // main.lua used day_of_year / season_from_default_ratio: the day of year in
    // default (14-day) season units, so the estrus schedule scales with the
    // world's configured season length instead of being tied to real seasons.
    const double day = to_days<double>( time_past_new_year( calendar::turn ) ) /
                       calendar::season_ratio();
    const auto day_in = [day]( double lo, double hi ) {
        return day >= lo && day <= hi;
    };

    // Strong "maid" estrus: nearly year-round heat with only short rests.
    if( mother.has_trait( trait_ESTRUS_MAID ) &&
        ( day_in( 1, 19 ) || day_in( 22, 40 ) || day_in( 41, 60 ) || day_in( 61, 79 ) ||
          day_in( 82, 100 ) || day_in( 101, 120 ) || day_in( 121, 125 ) ) ) {
        if( !mother.has_effect( effect_female_estrus ) ) {
            add_msg( m_good, string_format(
                         _( "%s에게 강렬한 발정기가 왔다. 지독한 발정에 뜨거운 숨을 내쉬며 온몸을 비볐다." ),
                         mother.disp_name() ) );
        }
        mother.add_effect( effect_female_estrus, 2_days );
    }

    const bool pregnant = mother.has_effect( effect_pregnantcy );
    const bool impregnated = mother.has_effect( effect_impregnated );
    if( !pregnant && !impregnated ) {
        // Not pregnant: lighter periodic estrus for animal/weak-maid traits.
        // Wolves: late-winter heat; cats and weak maids: heat every ~14 days.
        const bool feline_cycle = day_in( 3, 7 ) || day_in( 17, 21 ) || day_in( 31, 35 );
        const bool in_estrus = ( mother.has_trait( trait_ESTRUS_LUPINE ) && day_in( 0, 11 ) ) ||
                               ( ( mother.has_trait( trait_ESTRUS_FELINE ) ||
                                   mother.has_trait( trait_ESTRUS_MAID_WEAK ) ) && feline_cycle );
        if( in_estrus ) {
            if( !mother.has_effect( effect_estrus ) ) {
                add_msg( m_good, string_format( _( "%s에게 발정기가 왔다." ), mother.disp_name() ) );
            }
            mother.add_effect( effect_estrus, 1_days );
        }
        return;
    }

    // Convert a fresh conception into a tracked pregnancy.
    if( impregnated && !pregnant ) {
        mother.remove_effect( effect_impregnated );
        if( mother.is_avatar() ) {
            popup( string_format( _( "%s의 모습이 이상하다..." ), mother.get_name() ) );
            popup( string_format( _( "분명히.. %s는(은) 아이를 밴 것 같다." ), mother.get_name() ) );
        }
        // Nine stages over 90 days, with ten days per stage.
        mother.add_effect( effect_pregnantcy, 90_days );
    }
}

// main.lua birth_process: roll for childbirth once the pregnancy reaches term.
void birth_process( Character &mother )
{
    if( !mother.has_effect( effect_pregnantcy ) ) {
        return;
    }
    if( mother.get_effect_int( effect_pregnantcy ) != 1 ) {
        return; // only the final month
    }
    const time_duration dur = mother.get_effect_dur( effect_pregnantcy );
    const bool force_birth = dur <= 1_hours;
    if( !force_birth && rng( 1, 100 ) > 12 ) {
        mother.mod_pain( 25 );
        add_msg( m_bad, string_format( _( "%s가(이) 진통을 겪고 있다!" ), mother.disp_name() ) );
        return;
    }
    const std::vector<tripoint_bub_ms> locs = around_empty_locs( mother.bub_pos() );
    if( locs.empty() ) {
        return;
    }
    const tripoint_bub_ms loc = random_entry( locs );
    popup( string_format( _( "%s가(이) 아이를 낳았다!" ), mother.get_name() ) );
    mother.remove_effect( effect_pregnantcy );

    const int pregcount = std::atoi( mother.get_value( "hentai_pregcount" ).c_str() ) + 1;
    mother.set_value( "hentai_pregcount", std::to_string( pregcount ) );

    g->m.place_npc( loc, string_id<npc_template>( "darkdays_children" ) );
    popup( "%s", _( "그 때, 신기한 일이 벌어졌다. 아이들이 순식간에 성장했다." ) );
    g->m.add_item_or_charges( get_avatar().bub_pos(),
                              item::spawn( itype_id( "scroll_of_naming" ), calendar::turn ) );
    add_msg( m_good, _( "당신의 발 밑에 뭔가가 굴러왔다." ) );
    mother.mod_moves( -100 );
}
} // namespace

void on_day_passed()
{
    preg_process( get_avatar() );
    for( npc &n : g->all_npcs() ) {
        preg_process( n );
    }
}

void on_hour_passed()
{
    birth_process( get_avatar() );
    get_avatar().remove_effect( effect_gotwifed );
    for( npc &n : g->all_npcs() ) {
        birth_process( n );
        n.remove_effect( effect_gotwifed );
    }
}

void on_new_player( avatar &u )
{
    static const itype_id itype_fake_prof_pet( "fake_prof_pet" );
    static const efftype_id effect_pet( "pet" );
    if( !u.has_amount( itype_fake_prof_pet, 1 ) ) {
        return;
    }
    u.use_amount( itype_fake_prof_pet, 1 ); // consume the profession's dummy flag item

    // const.lua PROF_PET_LIST
    struct pet_choice {
        std::string entry;
        std::string mon_id;
        std::vector<std::string> bonus;
    };
    const std::vector<pet_choice> choices = {
        { _( "개다！" ), "mon_dog", { "pet_carrier", "dog_whistle" } },
        { _( "고양이다！" ), "mon_cat", { "pet_carrier", "can_tuna" } },
        { _( "곰이다！" ), "mon_bear_cub", {} },
        { _( "몽마다！" ), "mon_succubi", { "holy_choker" } }
    };

    uilist menu;
    menu.title = _( "당신의 펫은..." );
    for( size_t i = 0; i < choices.size(); i++ ) {
        menu.addentry( static_cast<int>( i ), true, MENU_AUTOASSIGN, choices[i].entry );
    }
    menu.query();
    const int sel = menu.ret >= 0 ? menu.ret : 0; // default to the first pet if cancelled

    const pet_choice &choice = choices[sel];
    if( monster *const pet = g->place_critter_around( mtype_id( choice.mon_id ), u.bub_pos(), 1 ) ) {
        pet->friendly = -1;
        pet->add_effect( effect_pet, 1_turns );
        if( pet->type->id == mtype_id( "mon_succubi" ) ) {
            // Don't let your own succubus pet pull the WIFE_U special.
            pet->disable_special( "WIFE_U" );
        }
    }
    for( const std::string &b : choice.bonus ) {
        u.i_add( item::spawn( itype_id( b ), calendar::turn ) );
    }
    u.mod_moves( -200 );
}

} // namespace hentai

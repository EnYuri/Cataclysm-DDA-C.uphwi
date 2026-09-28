#include "battle_maid.h"

#include <algorithm>
#include <cstdlib>
#include <string>
#include <vector>

#include "avatar.h"
#include "calendar.h"
#include "character.h"
#include "creature.h"
#include "effect.h"
#include "game.h"
#include "item.h"
#include "kill_tracker.h"
#include "map/map.h"
#include "map_iterator.h"
#include "messages.h"
#include "monster.h"
#include "mtype.h"
#include "output.h"
#include "rng.h"
#include "string_formatter.h"
#include "text_snippets.h"
#include "translations.h"
#include "type_id.h"

namespace
{
const mtype_id mon_shoggoth_maid( "mon_shoggoth_maid" );
const mtype_id mon_shoggoth_maid_unlimit( "mon_shoggoth_maid_unlimit" );
const mtype_id mon_shoggoth_maid_light( "mon_shoggoth_maid_light" );

const efftype_id effect_docile( "docile" );
const efftype_id effect_MB_UNLIMIT( "MB_UNLIMIT" );

const itype_id itype_res_shoggoth( "ext_res_shoggoth" );
const itype_id itype_loved_shoggoth( "loved_shoggoth" );

const trait_id trait_MB_MAID_ON_HEAD( "MB_MAID_ON_HEAD" );
const trait_id trait_MB_MAID_ON_HEAD2( "MB_MAID_ON_HEAD2" );
const trait_id trait_MB_MAID_ON_HEAD3( "MB_MAID_ON_HEAD3" );
const trait_id trait_MB_MAID_ON_HEAD4( "MB_MAID_ON_HEAD4" );

// main.lua trait_list
const std::vector<trait_id> onhead_traits = {
    trait_MB_MAID_ON_HEAD, trait_MB_MAID_ON_HEAD2,
    trait_MB_MAID_ON_HEAD3, trait_MB_MAID_ON_HEAD4
};

// main.lua MOD.talk_freq / MOD.maid_fickleness
const int TALK_FREQ = 20;
const int MAID_FICKLENESS = 10;

// preload.lua serch_arround() ranges
const int SEARCH_RANGE = 30;

bool is_bell_worn( const Character &who )
{
    return who.is_wearing( itype_res_shoggoth ) || who.is_wearing( itype_loved_shoggoth );
}

// main.lua set_onhead_trait / unset_onhead_trait
void unset_onhead_trait( Character &who )
{
    for( const trait_id &tid : onhead_traits ) {
        if( who.has_trait( tid ) ) {
            who.unset_mutation( tid );
        }
    }
}

void set_onhead_trait( Character &who )
{
    who.set_mutation( random_entry( onhead_traits ) );
}

// preload.lua remove_unlimit(): the "unlimit" timer ran out.
void end_unlimit( monster &z )
{
    battle_maid::say( _( "...후우\n 주인님! 괜찮으신가요?" ) );
    z.poly( mon_shoggoth_maid );
}

} // namespace

namespace battle_maid
{

bool is_shoggoth_maid( const monster &z )
{
    return z.type->id == mon_shoggoth_maid ||
           z.type->id == mon_shoggoth_maid_unlimit ||
           z.type->id == mon_shoggoth_maid_light;
}

std::vector<monster *> maids_around( int range, bool ( *pred )( const monster & ) )
{
    std::vector<monster *> found;
    const tripoint_bub_ms origin = get_avatar().bub_pos();
    for( monster &z : g->all_monsters() ) {
        if( z.is_dead() || !pred( z ) ) {
            continue;
        }
        if( square_dist( origin, z.bub_pos() ) <= range ) {
            found.push_back( &z );
        }
    }
    return found;
}

void normalize( monster &z )
{
    // The lighting / unlimit forms are separate types now, so reverting the type restores
    // speed and luminance in one step (Lua reset a global mtype instead).
    if( z.type->id != mon_shoggoth_maid && is_shoggoth_maid( z ) ) {
        z.poly( mon_shoggoth_maid );
    }
    z.set_speed_base( z.type->speed );
    z.remove_effect( effect_docile );
}

void make_docile( monster &z )
{
    z.add_effect( effect_docile, 1_turns );
    if( z.has_effect( effect_docile ) ) {
        z.get_effect( effect_docile ).set_permanent();
    }
}

std::vector<tripoint_bub_ms> empty_points_around( size_t count )
{
    std::vector<tripoint_bub_ms> points;
    const tripoint_bub_ms origin = get_avatar().bub_pos();
    for( int radius = 1; radius <= SEARCH_RANGE && points.size() < count; radius++ ) {
        for( const tripoint_bub_ms &p : points_in_radius( origin, radius ) ) {
            if( square_dist( origin, p ) != radius ) {
                continue; // already covered by an inner ring
            }
            if( g->is_empty( p ) ) {
                points.push_back( p );
                if( points.size() >= count ) {
                    break;
                }
            }
        }
    }
    return points;
}

bool salvation_bell( Character &who )
{
    static const mtype_id mon_lone_shoggoth_maid( "mon_lone_shoggoth_maid" );
    static const trait_id trait_MB_TRAIT_SALVATION( "MB_TRAIT_SALVATION" );
    static const itype_id itype_pair_master_doll( "pair_master_doll" );

    // serch_arround type 4: range 5, and she has to be in sight.
    std::vector<monster *> lone = maids_around( 5, []( const monster & m ) {
        return m.type->id == mon_lone_shoggoth_maid && get_avatar().sees( m );
    } );
    if( lone.empty() ) {
        return false;
    }
    monster &maid = *lone.front();

    const int guilt_count = g->get_kill_tracker().kill_count( mon_lone_shoggoth_maid );
    const int salv_count = std::atoi( who.get_value( "MB_SALV_COUNT" ).c_str() );

    who.mod_moves( -100 );
    popup( _( "떠도는 메이드 씨에게 들리도록 벨을 울렸다..." ) );

    // The more of her kin you have killed relative to those you have saved, the less likely
    // she is to listen.
    if( !one_in( 2 + std::max( guilt_count - salv_count, 0 ) ) ) {
        add_msg( _( "떠도는 메이드 씨의 움직임이 한순간 멈추었다..." ) );
        add_msg( _( "그러나 다시 날뛰기 시작했다..." ) );
        return true;
    }

    if( !who.has_trait( trait_MB_TRAIT_SALVATION ) ) {
        popup( _( "\"아아...아아...\"" ) );
        popup( _( "\"주인님...그곳에 계셨군요...\"" ) );
        popup( _( "\"지금, 곁에 있습니다♪\"" ) );
        popup( _( "\"이제...다시는 놓치지 않으니까요...!\"" ) );
        popup( _( "\"고맙습니다, 이름 모를 주인님♪\"" ) );
        who.set_mutation( trait_MB_TRAIT_SALVATION );
    } else {
        popup( _( "떠도는 메이드 씨는 만족스러운 표정을 짓고 그 자리에 푹 쓰러졌다..." ) );
    }

    // Lua rewrote lone_shoggoth_maid_drop's probabilities around die() so that she would leave a
    // pair_master_doll instead of the usual broken remains; place it directly instead.
    g->m.add_item_or_charges( maid.bub_pos(), item::spawn( itype_pair_master_doll,
                              calendar::turn ) );
    g->remove_zombie( maid );

    add_msg( _( "떠도는 메이드 씨를 구한 걸까?" ) );
    add_msg( _( "그렇게 믿고 싶다." ) );
    who.set_value( "MB_SALV_COUNT", std::to_string( salv_count + 1 ) );
    return true;
}

void say( const std::string &text )
{
    add_msg( m_good, "<color_yellow>\"%s\"</color>", text );
}

void say_snippet( const std::string &category )
{
    const translation line = SNIPPET.random_from_category( category ).value_or( translation() );
    if( !line.empty() ) {
        say( line.translated() );
    }
}

void on_item_wear( Character &who, const item &it )
{
    if( it.typeId() != itype_res_shoggoth && it.typeId() != itype_loved_shoggoth ) {
        return;
    }

    say_snippet( "maid_bell_wear" );

    if( it.typeId() == itype_loved_shoggoth ) {
        // Loading a save silently replays the wear hook, which used to stack a second
        // on-head trait; clearing first keeps exactly one.
        unset_onhead_trait( who );
        set_onhead_trait( who );
    }
}

void on_item_takeoff( Character &who, const item &it )
{
    if( it.typeId() != itype_res_shoggoth && it.typeId() != itype_loved_shoggoth ) {
        return;
    }

    say_snippet( "maid_bell_off" );

    if( it.typeId() == itype_loved_shoggoth ) {
        unset_onhead_trait( who );
    }
}

void on_fall_asleep( Character &who )
{
    if( !is_bell_worn( who ) ) {
        return;
    }
    say_snippet( "maid_bell_fallsleep" );
}

void on_turn()
{
    // Runs every turn from game::do_turn, so cost nothing when the mod is not loaded.
    if( !mon_shoggoth_maid.is_valid() ) {
        return;
    }

    avatar &u = get_avatar();

    // Unlimit upkeep runs regardless of what the avatar is wearing: keep the raging maid
    // close, and revert her once the effect lapses.
    for( monster *z : maids_around( 60, []( const monster & m ) {
    return m.type->id == mon_shoggoth_maid_unlimit;
    } ) ) {
        if( !z->has_effect( effect_MB_UNLIMIT ) ) {
            end_unlimit( *z );
            continue;
        }
        if( rl_dist( u.bub_pos(), z->bub_pos() ) > 8 ) {
            const std::vector<tripoint_bub_ms> spots = empty_points_around( 1 );
            if( !spots.empty() ) {
                z->setpos( spots.front() );
            }
        }
    }

    if( !is_bell_worn( u ) ) {
        return;
    }

    // main.lua: judge every 2 minutes (1 minute == 10 turns).
    if( !calendar::once_every( 2_minutes ) ) {
        return;
    }

    int freq = std::min( std::max( 1, TALK_FREQ ), 100 );

    const bool sleeping = u.has_effect( efftype_id( "sleep" ) );
    if( sleeping ) {
        freq *= 10; // quieter while the master sleeps
    }

    if( one_in( freq ) ) {
        if( g->is_hostile_nearby() ) {
            say_snippet( "maid_bell_danger" );
        } else if( sleeping ) {
            say_snippet( "maid_bell_sleep" );
        } else {
            say_snippet( "maid_bell_safe" );
        }
    }

    if( !u.is_wearing( itype_loved_shoggoth ) ) {
        return;
    }

    // main.lua: the on-head pose is re-rolled every 10 minutes.
    if( !calendar::once_every( 10_minutes ) ) {
        return;
    }

    const int fickleness = std::min( std::max( MAID_FICKLENESS, 1 ), 100 );
    if( fickleness == 100 || !one_in( fickleness ) ) {
        return;
    }

    unset_onhead_trait( u );
    set_onhead_trait( u );
}

} // namespace battle_maid

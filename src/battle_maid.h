#pragma once
#ifndef CATA_SRC_BATTLE_MAID_H
#define CATA_SRC_BATTLE_MAID_H

// cuphwi: native C++ port of the Battle_Maid_Bell (battle_maid_extend) Lua infrastructure.
// Replaces main.lua (chatter / on-head trait hooks) and preload.lua (the four iuse handlers
// plus their helpers). The iuse_actors themselves live in iuse_actor.{h,cpp}; everything they
// share lives here.
//
// Three Lua bugs are deliberately NOT reproduced:
//  1. "unlimit" and "lighting" mutated the *global* mtype (armour/melee/luminance), which leaked
//     across save/reload and permanently nerfed the maid via an inconsistent /4 revert path.
//     Both are now monster::poly() to a JSON variant, so all state lives on the instance.
//  2. maid_revert_to_item juggled item_group probabilities around monster::die(). Items are now
//     placed directly and the monster is removed without death drops.
//  3. serch_arround walked a 61x61 / 121x121 critter_at grid every call; we iterate live monsters.

#include <string>
#include <vector>

#include "coordinates.h"

class Character;
class item;
class monster;

namespace battle_maid
{

// --- shared classification -------------------------------------------------
// True for mon_shoggoth_maid and both of its poly variants (unlimit / light).
bool is_shoggoth_maid( const monster &z );

// Live monsters within `range` (square distance) of the avatar satisfying `pred`.
// Replaces serch_arround(); callers filter by type themselves.
std::vector<monster *> maids_around( int range, bool ( *pred )( const monster & ) );

// preload.lua maid_normalize(): back to the base type, normal speed, not docile.
void normalize( monster &z );

// Lua add_effect("docile", 1, "num_bp", true): passive until normalize() — permanent, not 1 turn.
void make_docile( monster &z );

// preload.lua get_arround_point(): up to `count` empty tiles around the avatar,
// nearest ring first.
std::vector<tripoint_bub_ms> empty_points_around( size_t count );

// preload.lua salvation_maid(): ringing the bell at a wandering (hostile) maid may put her to
// rest. Returns true if a wandering maid was in range, i.e. the bell did something.
bool salvation_bell( Character &who );

// main.lua msg_string_formater() + message(): yellow, quoted.
void say( const std::string &text );
// Pull a random snippet from `category` and say() it.
void say_snippet( const std::string &category );

// --- hooks (main.lua) ------------------------------------------------------
// on_player_item_wear / on_player_item_takeoff.
void on_item_wear( Character &who, const item &it );
void on_item_takeoff( Character &who, const item &it );
// on_activity_call_do_turn_finished for ACT_TRY_SLEEP.
void on_fall_asleep( Character &who );
// on_minute_passed: chatter, on-head trait reshuffle, and unlimit upkeep/expiry.
void on_turn();

} // namespace battle_maid

#endif // CATA_SRC_BATTLE_MAID_H

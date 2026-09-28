#pragma once
#ifndef CATA_SRC_HENTAI_SP_H
#define CATA_SRC_HENTAI_SP_H

// cuphwi: native C++ port of the Hentai_sp (mod_hentai_speech) Lua infrastructure.
// Replaces lua/util.lua, lua/translation.lua, repro helpers from preload.lua, and the
// shared bits of lua/monattack.lua. Used by monattack.cpp (the ported special attacks) and
// the ported iuse_actors. See .claude/HENTAI_CPP_PLAN.md for the full porting map.

#include <string>
#include <vector>

#include "coordinates.h"
#include "item.h"

class Character;
class Creature;
class monster;
class npc;
class avatar;
class player;

namespace hentai
{

// --- gendered text (translation.lua) ----------------------------------------
// true == male. Monsters: species FEMALE/HERM -> female, MALE/other -> male.
bool get_gender( const Creature &c );
// English-style pronoun substitution; the avatar always reads as second person.
std::string pro( const Creature &c, const std::string &pronoun );
// Returns you_word for the avatar, them_word for everyone else.
std::string you_word( const Creature &c, const std::string &you_w, const std::string &them_w );
// disp_name + conjugated word ("'s" handled specially, matching the Lua).
std::string actor_name( const Creature &c, const std::string &you_w,
                        const std::string &them_w = std::string() );

// --- classification (preload.lua) -------------------------------------------
bool is_cubi( const monster &z );

// --- randomized lewd sentence fragments (monattack.lua, concatenated) --------
std::string random_body_part();
std::string random_action();
std::string random_hip_action();

// --- geometry (monattack.lua / util.lua) ------------------------------------
// Heart curve (Love Formula). Note CDDA's y axis grows downward.
std::vector<tripoint_bub_ms> love_formula( const tripoint_bub_ms &center, int radius,
        double curvature );
// The (up to) 8 surrounding tiles plus centre that are currently empty.
std::vector<tripoint_bub_ms> around_empty_locs( const tripoint_bub_ms &center );
// Tiles within a Chebyshev ring [min_radius, max_radius] of centre (util.lua get_around_locs).
std::vector<tripoint_bub_ms> around_locs( const tripoint_bub_ms &center, int min_radius,
        int max_radius );

// --- reproduction helpers (monattack.lua / preload.lua) ---------------------
// INT-resisted application of the "corrupt" effect.
void gain_corrupt( Creature &target, int dur_turns );
// Lua add_effect(..., "num_bp", true): add `dur` and mark the effect permanent (never ticks down).
void add_permanent_effect( Creature &target, const efftype_id &eff, const time_duration &dur );
// Lua add_effect(eff, -1, ..., true): step a permanent counter effect down by one turn.
void reduce_counter_effect( Creature &target, const efftype_id &eff );
// The body-fluid item for a creature (player -> h_semen, monster -> d_cum), fresh.
detached_ptr<item> ejaculate_item( const Creature &c );
// Pregnancy chance roll (PREG_CHANCE plus estrus / contraception modifiers).
bool preg_roll( Character &mother );

// --- clothing / climax / virginity (util.lua / monattack.lua / preload.lua) --
// True if the character has nothing worn.
bool is_naked( const Character &c );
// A random worn item (nullptr if none).
item *get_random_wear( Character &c );
// "lust" climax check: if intensity >= 100, clear it (+ orgasm morale for players) and return true.
bool has_cum( Creature &c );
// Whether a monster can have its way with the target (exposed lower body + immobilised).
bool can_wife( monster &z, Character &target );
// Consume VIRGIN trait with morale + pain side effects.
void lost_virgin( Character &me, bool is_good );

// Build the randomized lewd flavour line for the SEDUCE attack (monattack.lua matk_seduce).
std::string seduce_message( const Creature &mon, const Character &target );

// --- the "fun" / SEX activity (lua activity.lua + preload.lua do_sex) ---------
// NPC willingness toward the act; sets is_love=true if driven by trust, false if by fear.
int get_willing( const npc &partner, bool &is_love );
// Whether the partner accepts; may clear device (raw) and shows flavour. Sets is_love.
bool is_accept_u( npc &partner, itype_id &device, bool &is_love );
// Begin the ACT_SEX activity (stores state on p, assigns activity, holds the partner).
void start_sex( avatar &p, npc *partner, const itype_id &device, bool is_love );
// ACT_SEX per-turn processing (morale + flavour).
void sex_do_turn( player &p );
// ACT_SEX completion (climax, opinions, pregnancy, products).
void sex_finish( player &p );

// --- periodic hooks (main.lua on_day_passed / on_hour_passed) -----------------
// Daily: estrus by trait + convert "impregnated" to "pregnantcy". Call once per game day.
void on_day_passed();
// Hourly: roll for childbirth + clear stray "gotwifed". Call once per game hour.
void on_hour_passed();
// New-character: the "man with a pet" profession's dummy item becomes a chosen starting pet.
void on_new_player( avatar &u );

} // namespace hentai

#endif // CATA_SRC_HENTAI_SP_H

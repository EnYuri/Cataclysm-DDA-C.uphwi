#pragma once
#ifndef DAMAGE_TYPE_H
#define DAMAGE_TYPE_H

#include <string>
#include <vector>

#include "string_id.h"

class JsonObject;
class Skill;
using skill_id = string_id<Skill>;

struct damage_type_def;
using damage_type_id = string_id<damage_type_def>;

// JSON-loadable metadata for a damage type.
// Phase 1: mirrors the existing enum damage_type via legacy_dt.
// Phase 2: mod-defined types get IDs assigned during finalize_all().
struct damage_type_def {
    damage_type_id id;
    bool was_loaded = false;

    std::string name;        // untranslated key used for display
    bool physical = false;   // is this a physical damage type?
    skill_id fighting_skill; // skill applied when dealing this damage
    // For built-in types: set from JSON (1–9). For mod types: assigned in finalize_all().
    mutable int legacy_dt = -1;

    void load( JsonObject &jo, const std::string &src );

    static void load_all( JsonObject &jo, const std::string &src );
    static void reset();
    static void finalize_all(); // assigns IDs to mod-defined types, sets total count
    static const std::vector<damage_type_def> &get_all();

    // Returns the def whose legacy_dt matches dt_enum, or nullptr if not found.
    static const damage_type_def *find_by_legacy( int dt_enum );
};

// Total registered damage types (built-in + mod-defined).
// Returns NUM_DT before finalize_all() has run.
int total_damage_types();

#endif // DAMAGE_TYPE_H

#include "damage_type.h"

#include <string>
#include <vector>

#include "damage.h"
#include "debug.h"
#include "generic_factory.h"
#include "json.h"
#include "skill.h"

namespace
{
generic_factory<damage_type_def> damage_type_factory( "damage_type" );
static int s_total_dt = NUM_DT; // updated in finalize_all()
} // namespace

template<>
bool string_id<damage_type_def>::is_valid() const
{
    return damage_type_factory.is_valid( *this );
}

template<>
const damage_type_def &string_id<damage_type_def>::obj() const
{
    return damage_type_factory.obj( *this );
}

void damage_type_def::load( JsonObject &jo, const std::string & )
{
    mandatory( jo, was_loaded, "name", name );
    optional( jo, was_loaded, "physical", physical, false );
    optional( jo, was_loaded, "fighting_skill", fighting_skill, skill_id::NULL_ID() );
    optional( jo, was_loaded, "legacy_dt", legacy_dt, -1 );
}

void damage_type_def::load_all( JsonObject &jo, const std::string &src )
{
    damage_type_factory.load( jo, src );
}

void damage_type_def::reset()
{
    damage_type_factory.reset();
    s_total_dt = NUM_DT;
}

void damage_type_def::finalize_all()
{
    // Assign integer IDs to mod-defined types (those that didn't set legacy_dt in JSON).
    int next_id = NUM_DT;
    for( const damage_type_def &def : damage_type_factory.get_all() ) {
        if( def.legacy_dt == -1 ) {
            def.legacy_dt = next_id++;
        }
    }
    s_total_dt = next_id;
}

int total_damage_types()
{
    return s_total_dt;
}

const std::vector<damage_type_def> &damage_type_def::get_all()
{
    return damage_type_factory.get_all();
}

const damage_type_def *damage_type_def::find_by_legacy( int dt_enum )
{
    for( const damage_type_def &def : damage_type_factory.get_all() ) {
        if( def.legacy_dt == dt_enum ) {
            return &def;
        }
    }
    return nullptr;
}

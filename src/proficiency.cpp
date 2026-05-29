#include "proficiency.h"

#include <string>
#include <vector>

#include "debug.h"
#include "generic_factory.h"
#include "json.h"

namespace
{
generic_factory<proficiency> proficiency_factory( "proficiency" );
} // namespace

template<>
bool string_id<proficiency>::is_valid() const
{
    return proficiency_factory.is_valid( *this );
}

template<>
const proficiency &string_id<proficiency>::obj() const
{
    return proficiency_factory.obj( *this );
}

void proficiency::load( JsonObject &jo, const std::string & )
{
    mandatory( jo, was_loaded, "name", name_, translated_string_reader );
    optional( jo, was_loaded, "description", description_, translated_string_reader );
    optional( jo, was_loaded, "default_time_multiplier", default_time_multiplier_, 2.0f );
    optional( jo, was_loaded, "default_fail_multiplier", default_fail_multiplier_, 1.5f );
    assign( jo, "time_to_learn", time_to_learn_, false, 1_hours );
    optional( jo, was_loaded, "required_proficiencies", required_proficiencies_,
              string_id_reader<proficiency> {} );
}

void proficiency::load_all( JsonObject &jo, const std::string &src )
{
    proficiency_factory.load( jo, src );
}

void proficiency::reset()
{
    proficiency_factory.reset();
}

const std::vector<proficiency> &proficiency::get_all()
{
    return proficiency_factory.get_all();
}

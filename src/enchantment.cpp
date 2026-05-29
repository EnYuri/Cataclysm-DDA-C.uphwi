#include "enchantment.h"

#include <map>
#include <string>
#include <vector>

#include "debug.h"
#include "generic_factory.h"
#include "json.h"

namespace
{
generic_factory<enchantment> enchantment_factory( "enchantment" );
} // namespace

template<>
bool string_id<enchantment>::is_valid() const
{
    return enchantment_factory.is_valid( *this );
}

template<>
const enchantment &string_id<enchantment>::obj() const
{
    return enchantment_factory.obj( *this );
}

static const std::map<std::string, enchant_val> enchant_val_map = {
    { "STRENGTH",     enchant_val::STRENGTH },
    { "STR",          enchant_val::STRENGTH },
    { "DEXTERITY",    enchant_val::DEXTERITY },
    { "DEX",          enchant_val::DEXTERITY },
    { "INTELLIGENCE", enchant_val::INTELLIGENCE },
    { "INT",          enchant_val::INTELLIGENCE },
    { "PERCEPTION",   enchant_val::PERCEPTION },
    { "PER",          enchant_val::PERCEPTION },
    { "SPEED",        enchant_val::SPEED },
    { "MAX_HP",       enchant_val::MAX_HP },
    { "DODGE",        enchant_val::DODGE },
    { "HIT",          enchant_val::HIT },
    { "TO_HIT",       enchant_val::HIT },
};

int enchantment::get_value_add( enchant_val val ) const
{
    int total = 0;
    for( const enchant_entry &e : values_ ) {
        if( e.value == val ) {
            total += e.add;
        }
    }
    return total;
}

void enchantment::load( JsonObject &jo, const std::string & )
{
    if( jo.has_member( "condition" ) ) {
        const std::string cond_str = jo.get_string( "condition" );
        if( cond_str == "ACTIVE" ) {
            condition_ = enchant_condition::ACTIVE;
        } else if( cond_str == "INACTIVE" ) {
            condition_ = enchant_condition::INACTIVE;
        } else {
            condition_ = enchant_condition::ALWAYS;
        }
    } else if( !was_loaded ) {
        condition_ = enchant_condition::ALWAYS;
    }

    if( jo.has_array( "values" ) ) {
        values_.clear();
        auto arr = jo.get_array( "values" );
        while( arr.has_more() ) {
            auto vjo = arr.next_object();
            const std::string val_str = vjo.get_string( "value" );
            const auto it = enchant_val_map.find( val_str );
            if( it == enchant_val_map.end() ) {
                continue;
            }
            enchant_entry entry;
            entry.value = it->second;
            entry.add   = vjo.get_int( "add", 0 );
            if( entry.add != 0 ) {
                values_.push_back( entry );
            }
        }
    }
}

void enchantment::load_all( JsonObject &jo, const std::string &src )
{
    enchantment_factory.load( jo, src );
}

void enchantment::reset()
{
    enchantment_factory.reset();
}

const std::vector<enchantment> &enchantment::get_all()
{
    return enchantment_factory.get_all();
}

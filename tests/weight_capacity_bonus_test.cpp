#include "avatar.h"
#include "calendar.h"
#include "catch/catch.hpp"
#include "character.h"
#include "game.h"
#include "item.h"
#include "player_helpers.h"
#include "state_helpers.h"
#include "units.h"

// worn armor's weight_capacity_bonus must add to Character::weight_capacity.
// Note: mod items cannot be tested here — the test harness loads core data only.
TEST_CASE( "worn armor weight_capacity_bonus applies", "[character][item]" )
{
    player &dummy = g->u;
    clear_character( dummy, false );
    const units::mass base = dummy.weight_capacity();

    dummy.wear_item( item::spawn( "power_armor_exo_1_on" ) );
    CHECK( dummy.weight_capacity() == base + 25_kilogram );
}

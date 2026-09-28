#include "avatar.h"
#include "cata_utility.h"
#include "catch/catch.hpp"
#include "faction.h"
#include "game.h"
#include "map/map.h"
#include "map_helpers.h"
#include "npc.h"
#include "player_helpers.h"
#include "state_helpers.h"
#include "type_id.h"
#include "vehicle/vehicle.h"
#include "vehicle/vehicle_part.h"

#include <ranges>

TEST_CASE("npc_keeps_seat_with_boardable_cargo_underneath", "[npc][vehicle][boarding]") {
    clear_all_state();
    const auto cleanup = on_out_of_scope([]() { clear_all_state(); });
    build_test_map(ter_id("t_pavement"));
    auto& here = get_map();
    auto& you = get_avatar();
    const auto origin = tripoint_bub_ms(60, 60, 0);
    auto* veh = here.add_vehicle(vproto_id("none"), origin, 0_degrees, 0, 0);
    REQUIRE(veh != nullptr);

    const auto cargo_first = GENERATE(false, true);
    const auto assigned = GENERATE(false, true);
    CAPTURE(cargo_first, assigned);
    const auto npc_mount = tripoint_mnt_veh(1, 0, 0);
    for (const auto mount : {tripoint_mnt_veh::zero(), npc_mount, tripoint_mnt_veh(2, 0, 0)}) {
        REQUIRE(veh->install_part(mount, vpart_id("frame_vertical"), true) >= 0);
    }
    const auto cargo_id = vpart_id("test_npc_boarding_cargo_under");
    if (cargo_first) { REQUIRE(veh->install_part(npc_mount, cargo_id, true) >= 0); }
    const auto seat_id = vpart_id("test_npc_boarding_seat");
    REQUIRE(veh->install_part(tripoint_mnt_veh::zero(), seat_id, true) >= 0);
    const auto seat = veh->install_part(npc_mount, seat_id, true);
    REQUIRE(seat >= 0);
    REQUIRE(veh->install_part(tripoint_mnt_veh(2, 0, 0), seat_id, true) >= 0);
    if (!cargo_first) { REQUIRE(veh->install_part(npc_mount, cargo_id, true) >= 0); }

    here.add_vehicle_to_cache(veh);
    here.build_map_cache(0);
    you.setpos(origin);
    here.board_vehicle(origin, &you);
    REQUIRE(you.in_vehicle);

    auto& follower = spawn_npc(origin + point(5, 0), "test_talker");
    follower.set_fac(faction_id("your_followers"));
    follower.set_attitude(NPCATT_FOLLOW);
    REQUIRE(follower.is_player_ally());
    if (assigned) { REQUIRE(veh->part(seat).set_crew(follower)); }
    const auto seat_pos = veh->bub_part_location(seat);
    follower.setpos(seat_pos);
    here.board_vehicle(seat_pos, &follower);
    REQUIRE(follower.in_vehicle);
    REQUIRE(veh->get_passenger(seat) == &follower);

    for (const auto turn : std::views::iota(0, 4)) {
        CAPTURE(turn);
        follower.set_moves(100);
        follower.execute_action("npc_follow_embarked");
        CHECK(follower.bub_pos() == seat_pos);
        CHECK(follower.in_vehicle);
        CHECK(veh->get_passenger(seat) == &follower);
    }
}

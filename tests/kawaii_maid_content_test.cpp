#include "catch/catch.hpp"
#include "flag.h"
#include "item.h"
#include "item_factory.h"
#include "itype.h"
#include "mutation.h"
#include "npc.h"
#include "type_id.h"
#include "vehicle/veh_type.h"

#include <algorithm>
#include <array>
#include <ranges>
#include <set>

TEST_CASE("maid_workshops_do_not_emulate_artifacts_or_combat_equipment", "[.][kawaii][tools]") {
    const auto excluded = std::array{
        "gloople",
        "glooplegrow",
        "gray",
        "graygrow",
        "oozle",
        "oozlegrow",
        "dbone_longsword",
        "black_dbone_longsword",
        "a_longsword",
        "sq_walkergun7",
        "draconic_heart_mutator",
        "master_doll_vibe_on",
        "sun_sword",
        "book_summoning"};
    for (const auto id :
         {"kawaii_maid_subtool_set", "kawaii_maid_biotool_set_toolset",
          "kawaii_maid_biotool_actionset", "kawaii_maid_biotool_actionset_high",
          "kawaii_maid_car_craft_i", "kawaii_maid_crafter_toolset"}) {
        CAPTURE(id);
        const auto type = itype_id(id);
        REQUIRE(type.is_valid());
        REQUIRE(type->tool);
        for (const auto banned : excluded) {
            CAPTURE(banned);
            CHECK(std::ranges::find(type->tool->subtype, itype_id(banned))
                  == type->tool->subtype.end());
        }
        CHECK(std::ranges::find(type->tool->subtype, itype_id("welder"))
              != type->tool->subtype.end());
    }
    for (const auto id : {"kawaii_maid_car_craft", "kawaii_maid_car_craft_under"}) {
        const auto type = vpart_id(id);
        REQUIRE(type.is_valid());
        const auto tools = type->craftertools();
        for (const auto banned : excluded) {
            CAPTURE(id, banned);
            CHECK(std::ranges::find(tools, itype_id(banned)) == tools.end());
        }
        CHECK(std::ranges::find(tools, itype_id("kawaii_maid_sewing_inner")) != tools.end());
        CHECK(std::ranges::find(tools, itype_id("kawaii_maid_welder_inner")) != tools.end());
    }
}

TEST_CASE(
    "maid_category_mutations_can_be_acquired_with_their_requirements", "[.][kawaii][mutation]") {
    for (const auto category :
         {"WHITE_MAID", "CORESTR", "COREDEX", "COREINT", "COREPER", "COREALL", "COREFAT",
          "COREFATH", "COREFATU", "COREFATS"}) {
        const auto category_id = mutation_category_id(category);
        const auto& candidates = mutations_category.at(category_id);
        REQUIRE_FALSE(candidates.empty());
        for (const auto& target : candidates) {
            CAPTURE(category, target);
            const auto& branch = target.obj();
            if (branch.profession || branch.threshold) { continue; }
            auto dummy = npc();
            std::set<trait_id> parents;
            for (const auto* group : {&branch.prereqs, &branch.prereqs2}) {
                if (!group->empty()) {
                    REQUIRE(group->front().is_valid());
                    dummy.set_mutation(group->front());
                    parents.insert(group->front());
                }
            }
            if (branch.threshold_tier != 0) {
                CHECK_FALSE(dummy.mutate_towards(target));
                CHECK_FALSE(dummy.has_trait(target));
                REQUIRE(branch.threshold_tier < category_id->threshold_muts.size());
                dummy.set_mutation(category_id->threshold_muts[branch.threshold_tier]);
            }
            REQUIRE(dummy.mutate_towards(target));
            REQUIRE(dummy.has_trait(target));
            for (const auto& parent : parents) {
                if (std::ranges::find(parent->replacements, target) != parent->replacements.end()) {
                    CHECK_FALSE(dummy.has_trait(parent));
                }
            }
            for (const auto& style : branch.initial_ma_styles) { CHECK(style.is_valid()); }
        }
    }
}

TEST_CASE("maid_regeneration_replaces_tough_and_reverts_when_removed", "[.][kawaii][mutation]") {
    auto dummy = npc();
    dummy.set_mutation(trait_id("TOUGH"));
    REQUIRE(dummy.mutate_towards(trait_id("MAID_REGEN_1")));
    CHECK_FALSE(dummy.has_trait(trait_id("TOUGH")));
    dummy.remove_mutation(trait_id("MAID_REGEN_1"));
    CHECK(dummy.has_trait(trait_id("TOUGH")));
    CHECK_FALSE(dummy.has_trait(trait_id("MAID_REGEN_1")));
}

TEST_CASE("maid_elixir_stat_stages_do_not_stack", "[.][kawaii][mutation]") {
    for (const auto category : {"CORESTR", "COREDEX", "COREINT", "COREPER", "COREALL"}) {
        auto dummy = npc();
        const auto str = dummy.get_str_base();
        const auto dex = dummy.get_dex_base();
        const auto intel = dummy.get_int_base();
        const auto per = dummy.get_per_base();
        const auto all = std::string(category) == "COREALL";
        auto previous = trait_id::NULL_ID();
        for (auto level = 1; level <= (all ? 2 : 4); ++level) {
            const auto target = trait_id(
                all ? (level == 1 ? "COREALL_START" : "COREALL_UP1")
                    : std::string(category) + "_UP" + std::to_string(level));
            CAPTURE(category, level);
            REQUIRE(dummy.mutate_towards(target));
            REQUIRE(dummy.has_trait(target));
            if (previous) { CHECK_FALSE(dummy.has_trait(previous)); }
            CHECK(dummy.get_str_base()
                  == str + (all || std::string(category) == "CORESTR" ? level : 0));
            CHECK(dummy.get_dex_base()
                  == dex + (all || std::string(category) == "COREDEX" ? level : 0));
            CHECK(dummy.get_int_base()
                  == intel + (all || std::string(category) == "COREINT" ? level : 0));
            CHECK(dummy.get_per_base()
                  == per + (all || std::string(category) == "COREPER" ? level : 0));
            previous = target;
        }
    }
}

TEST_CASE("all_maid_wearables_support_repair_and_refitting", "[.][kawaii][armor]") {
    auto checked = 0;
    for (const auto* type : item_controller->all()) {
        if (!type->armor || !std::ranges::any_of(type->src, [](const auto& source) {
                return source.second == mod_id("KawaiiMaidMod");
            })) {
            continue;
        }
        CAPTURE(type->get_id());
        const auto clothing = item::spawn(type->get_id());
        CHECK(clothing->has_flag(flag_VARSIZE));
        CHECK_FALSE(clothing->has_flag(flag_NO_REPAIR));
        CHECK_FALSE(clothing->repaired_with().empty());
        ++checked;
    }
    CHECK(checked > 0);
}

TEST_CASE(
    "maid_mutation_progression_preserves_thresholds_and_replaces_prerequisites",
    "[.][kawaii][mutation]") {
    auto dummy = npc();
    dummy.set_mutation(trait_id("LUNGS"));
    REQUIRE(dummy.mutate_towards(trait_id("LUNGS_2")));
    CHECK(dummy.has_trait(trait_id("LUNGS_2")));
    CHECK_FALSE(dummy.has_trait(trait_id("LUNGS")));

    const auto& candidates = mutations_category.at(mutation_category_id("WHITE_MAID"));
    for (const auto id : {"MAID_REGEN_1", "MAID_REGEN_2", "MAID_REGEN_3"}) {
        CAPTURE(id);
        CHECK(std::ranges::find(candidates, trait_id(id)) != candidates.end());
    }

    dummy.set_mutation(trait_id("MAID_LUNG_2"));
    CHECK_FALSE(dummy.mutate_towards(trait_id("MAID_WHITE_BREATH")));
    CHECK_FALSE(dummy.has_trait(trait_id("MAID_WHITE_BREATH")));
    dummy.set_mutation(trait_id("THRESH_WHITE_MAID"));
    REQUIRE(dummy.mutate_towards(trait_id("MAID_WHITE_BREATH")));
    CHECK(dummy.has_trait(trait_id("MAID_WHITE_BREATH")));
    CHECK_FALSE(dummy.has_trait(trait_id("MAID_LUNG_2")));
}

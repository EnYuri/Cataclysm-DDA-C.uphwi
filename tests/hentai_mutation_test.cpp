#include "avatar.h"
#include "calendar.h"
#include "catch/catch.hpp"
#include "effect.h"
#include "hentai_sp.h"
#include "mutation.h"
#include "npc.h"
#include "player_helpers.h"
#include "string_formatter.h"
#include "type_id.h"

#include <ranges>

TEST_CASE("hentai_mutation_prerequisites_and_thresholds_are_obtainable", "[.][hentai][mutation]") {
    for (const auto name :
         {"VIRGIN", "SMALL_BREAST", "BIG_BREAST", "MULTI_BREAST", "ESTRUS_LUPINE", "ESTRUS_FELINE",
          "OVIPARITY_BIRD", "OVIPARITY_LIZARD", "OVIPARITY_INSECT", "OVIPOSITOR", "TAIL_FIEND"}) {
        const auto target = trait_id(name);
        CAPTURE(target);
        REQUIRE(target.is_valid());
        auto dummy = npc();
        for (const auto* group : {&target->prereqs, &target->prereqs2}) {
            if (!group->empty()) { dummy.set_mutation(group->front()); }
        }
        if (target->threshold_tier != 0) {
            CHECK_FALSE(dummy.mutate_towards(target));
            dummy.set_mutation(target->category.front()->threshold_muts.at(target->threshold_tier));
        }
        REQUIRE(dummy.mutate_towards(target));
        CHECK(dummy.has_trait(target));
    }
}

TEST_CASE("maid_mutation_buff_lasts_through_daily_ticks", "[.][hentai-buffs]") {
    const auto previous_turn = calendar::turn;
    clear_avatar();
    auto& dummy = get_avatar();
    const auto buff = efftype_id("female_estrus");
    dummy.set_mutation(trait_id("ESTRUS_MAID"));
    calendar::turn = calendar::turn_zero + 4_days;
    hentai::on_day_passed();
    CHECK(dummy.get_effect_dur(buff) == 2_days);
    CHECK(dummy.get_effect_int(buff) == 4);
    auto& active = dummy.get_effect(buff);
    active.mod_duration(-13_hours);
    CHECK(dummy.has_effect(buff));
    CHECK(dummy.get_effect_int(buff) == 3);
    CHECK(active.get_mod("INT") == -5);
    CHECK(active.get_mod("SPEED") == 8);
    calendar::turn += 1_days;
    hentai::on_day_passed();
    CHECK(dummy.get_effect_dur(buff) == 2_days);
    CHECK(dummy.get_effect_int(buff) == 4);
    clear_avatar();
    calendar::turn = previous_turn;
}

TEST_CASE("hentai_buff_probability_uses_multipliers", "[.][hentai-buffs]") {
    struct probability_case {
        bool weak;
        bool strong;
        bool contraception;
        double expected;
        double tolerance;
    };
    for (const auto scenario :
         {probability_case{false, false, false, 0.10, 0.015},
          probability_case{true, false, false, 0.50, 0.025},
          probability_case{false, true, false, 1.00, 0.0},
          probability_case{true, true, false, 1.00, 0.0},
          probability_case{false, false, true, 0.001, 0.001},
          probability_case{false, true, true, 0.02, 0.008},
          probability_case{true, true, true, 0.02, 0.008}}) {
        CAPTURE(scenario.weak, scenario.strong, scenario.contraception);
        auto dummy = npc();
        if (scenario.contraception) { dummy.add_effect(efftype_id("contraception"), 1_days); }
        if (scenario.weak) { dummy.add_effect(efftype_id("estrus"), 1_days); }
        if (scenario.strong) { dummy.add_effect(efftype_id("female_estrus"), 2_days); }
        auto successes = 0;
        const auto trials = 20000;
        for (auto trial = 0; trial < trials; ++trial) {
            successes += hentai::preg_roll(dummy) ? 1 : 0;
        }
        const auto probability = static_cast<double>(successes) / trials;
        CHECK(probability >= scenario.expected - scenario.tolerance);
        CHECK(probability <= scenario.expected + scenario.tolerance);
    }
}

TEST_CASE("hentai_fiend_additions_preserve_base_mutations", "[.][hentai][mutation]") {
    for (const auto& target : mutations_category.at(mutation_category_id("FIEND"))) {
        CAPTURE(target);
        auto candidate = npc();
        for (const auto* group : {&target->prereqs, &target->prereqs2}) {
            if (!group->empty()) { candidate.set_mutation(group->front()); }
        }
        if (target->threshold_tier != 0) { candidate.set_mutation(trait_id("THRESH_FIEND")); }
        REQUIRE(candidate.mutate_towards(target));
        CHECK(candidate.has_trait(target));
    }
    const auto& attack = trait_id("OVIPOSITOR")->attacks_granted;
    REQUIRE(attack.size() == 1);
    const auto message = string_format(attack.front().attack_text_npc, "Alice", "Bob");
    CHECK(message.find("Alice") != std::string::npos);
    CHECK(message.find("Bob") != std::string::npos);
    CHECK(std::ranges::find(trait_id("FANGS")->category, mutation_category_id("FIEND"))
          != trait_id("FANGS")->category.end());
    auto dummy = npc();
    dummy.set_mutation(trait_id("PSYCHOPATH"));
    CHECK(dummy.has_trait_flag(trait_flag_str_id("PSYCHOPATH")));
    dummy.set_mutation(trait_id("TAIL_LONG"));
    REQUIRE(dummy.mutate_towards(trait_id("TAIL_FIEND")));
    CHECK(dummy.has_trait(trait_id("TAIL_FIEND")));
    CHECK_FALSE(dummy.has_trait(trait_id("TAIL_LONG")));
    dummy.remove_mutation(trait_id("TAIL_FIEND"));
    CHECK(dummy.has_trait(trait_id("TAIL_LONG")));
}

TEST_CASE("hentai_alone_preserves_vanilla_mutation_categories", "[.][hentai-base][mutation]") {
    CHECK(std::ranges::find(trait_id("FANGS")->category, mutation_category_id("LUPINE"))
          != trait_id("FANGS")->category.end());
    CHECK(std::ranges::find(trait_id("FANGS")->category, mutation_category_id("FISH"))
          != trait_id("FANGS")->category.end());
}

TEST_CASE("hentai_animal_mutation_seasons_match_their_descriptions", "[.][hentai][mutation]") {
    const auto previous_turn = calendar::turn;
    const auto estrus = efftype_id("estrus");
    for (const auto trait : {"ESTRUS_LUPINE", "ESTRUS_FELINE"}) {
        for (auto season = 0; season < 4; ++season) {
            CAPTURE(trait, season);
            clear_avatar();
            auto& dummy = get_avatar();
            dummy.set_mutation(trait_id(trait));
            calendar::turn = calendar::turn_zero + calendar::season_length() * season + 4_days;
            hentai::on_day_passed();
            CHECK(
                dummy.has_effect(estrus) == (std::string(trait) == "ESTRUS_FELINE" || season == 0));
        }
    }
    clear_avatar();
    calendar::turn = previous_turn;
}

TEST_CASE("hentai_positive_appearance_mutation_improves_npc_reaction", "[.][hentai][mutation]") {
    clear_avatar();
    auto& dummy = get_avatar();
    auto observer = npc();
    observer.form_opinion(dummy);
    const auto initial_fear = observer.op_of_u.fear;
    dummy.set_mutation(trait_id("BIG_BREAST"));
    observer.op_of_u = {};
    observer.form_opinion(dummy);
    CHECK(observer.op_of_u.fear < initial_fear);
    clear_avatar();
}

#include "catch/catch.hpp"
#include "color.h"
#include "inventory.h"
#include "item.h"
#include "output.h"
#include "recipe.h"
#include "recipe_dictionary.h"
#include "requirements.h"
#include "type_id.h"

#include <map>
#include <set>
#include <string>
#include <utility>

TEST_CASE("No book grant a recipe at skill levels above autolearn", "[recipe]") {
    for (const recipe* rec : recipe_dict.all_autolearn()) {
        // Booklearning requires only one skill - the primary one
        // If autolearn requires any other skill, booklearn is not 100% useless
        if (rec->autolearn_requirements.size() > 1
            || !rec->autolearn_requirements.contains(rec->skill_used)) {
            continue;
        }
        for (const auto& p : rec->booksets) {
            const std::string recipe_ident = rec->ident().str();
            const std::string item_type = rec->result().str();
            const std::string item_name = item::nname(rec->result());
            const std::string bookname = item::nname(p.first);
            CAPTURE(recipe_ident);
            CAPTURE(item_type);
            CAPTURE(item_name);
            CAPTURE(bookname);
            CHECK(p.second < rec->autolearn_requirements.begin()->second);
        }
    }
}

TEST_CASE("Vehicle tool alternatives start on separate lines", "[requirements]") {
    const auto reqs = requirement_data(
                          { { tool_comp( itype_id( "welder" ), 10 ),
                              tool_comp( itype_id( "toolset" ), 10 ) } }, {}, {} );
    const auto inv = inventory();
    const auto lines = reqs.get_folded_tools_list( 80, c_white, inv, 1, true );
    REQUIRE( lines.size() == 3 );
    CHECK( remove_color_tags( lines[1] ).starts_with( "> " ) );
    CHECK( remove_color_tags( lines[2] ).starts_with( "  " ) );
}

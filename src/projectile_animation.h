#pragma once

#include "projectile.h"

/// Display-only beam marker; it does not give a projectile LASER collision behavior.
inline auto projectile_draws_energy_beam( const projectile &proj ) -> bool
{
    static const auto effect = ammo_effect_str_id( "DRAW_ENERGY_BEAM" );
    return proj.has_effect( effect );
}

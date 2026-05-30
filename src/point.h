#pragma once
#ifndef POINT_H
#define POINT_H

// Forwarding header for the basic coordinate value types (point, tripoint,
// rl_vec2d, rl_vec3d, box, rectangle, sphere, ...).
//
// In this 0.D-era fork those types are defined in enums.h. Bright Nights and
// later CDDA split them into a dedicated point.h. Code ported from BN expects to
// `#include "point.h"` and get the raw coordinate types, and the strong-typed
// coordinate wrappers in coordinates.h (also ported from BN) include "point.h".
//
// Rather than physically move the definitions out of enums.h (a large, risky
// transcription), this header simply forwards to enums.h. The net effect for
// ported code is identical: including point.h provides point/tripoint/etc.
//
// A true physical split of these types into this file can be done later; it is
// purely cosmetic for compilation purposes and not required for the migration.
#include "enums.h"

#endif // POINT_H

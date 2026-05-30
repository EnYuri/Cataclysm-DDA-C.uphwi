#pragma once
#ifndef POINT_FLOAT_H
#define POINT_FLOAT_H

// Forwarding header for the floating-point coordinate types (rl_vec2d, rl_vec3d).
//
// In this 0.D-era fork those types live in line.h. Bright Nights / later CDDA put
// them in a dedicated point_float.h, and coordinates.h (ported from BN) includes
// "point_float.h". Our rl_vec2d/rl_vec3d are layout- and API-compatible with BN's
// (public float x/y/z members, the same operators, and now a `dimension` member),
// so forwarding to line.h satisfies ported code without duplicating the types.
#include "line.h"

#endif // POINT_FLOAT_H

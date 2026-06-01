#pragma once
#ifndef ENUM_TRAITS_H
#define ENUM_TRAITS_H

#include <type_traits>

// Specialize enum_traits<E> with a `last` member to describe an enum's range.
// Ported verbatim from Bright Nights src/enum_traits.h.
template<typename E>
struct enum_traits;

namespace enum_traits_detail
{

template<typename E>
using last_type = std::decay_t<decltype( enum_traits<E>::last )>;

} // namespace enum_traits_detail

template<typename E, typename U = E>
struct has_enum_traits : std::false_type {};

template<typename E>
struct has_enum_traits<E, enum_traits_detail::last_type<E>> : std::true_type {};

#endif // ENUM_TRAITS_H

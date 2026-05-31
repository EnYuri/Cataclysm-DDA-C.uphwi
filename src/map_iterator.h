#pragma once
#ifndef MAP_ITERATOR_H
#define MAP_ITERATOR_H

#include <cstddef>
#include <algorithm>
#include <ranges>

#include "enums.h"
#include "point_traits.h"

class tripoint_range
{
    private:
        /**
         * Generates points in a rectangle.
         */
        class point_generator
        {
                friend class tripoint_range;
            private:
                tripoint p;
                const tripoint_range &range;
            public:
                typedef tripoint                    value_type;
                typedef std::ptrdiff_t              difference_type;
                typedef tripoint                   *pointer;
                typedef tripoint                   &reference;
                typedef std::forward_iterator_tag   iterator_category;

                point_generator( const tripoint &_p, const tripoint_range &_range )
                    : p( _p ), range( _range ) {
                }

                // Increment x, then if it goes outside range, "wrap around" and increment y
                // Same for y and z
                inline point_generator &operator++() {
                    p.x++;
                    if( p.x <= range.maxp.x ) {
                        return *this;
                    }

                    p.y++;
                    p.x = range.minp.x;
                    if( p.y <= range.maxp.y ) {
                        return *this;
                    }

                    p.z++;
                    p.y = range.minp.y;
                    return *this;
                }

                inline const tripoint &operator*() const {
                    return p;
                }

                inline bool operator!=( const point_generator &other ) const {
                    // Reverse coordinates order, because it will usually only be compared with endpoint
                    // which will always differ in Z, except for the very last comparison
                    const tripoint &pt = other.p;
                    return p.z != pt.z || p.y != pt.y || p.x != pt.x;
                }

                inline bool operator==( const point_generator &other ) const {
                    return !( *this != other );
                }
        };

        tripoint minp;
        tripoint maxp;
    public:
        typedef point_generator::value_type         value_type;
        typedef point_generator::difference_type    difference_type;
        typedef point_generator::pointer            pointer;
        typedef point_generator::reference          reference;
        typedef point_generator::iterator_category  iterator_category;

        tripoint_range( const tripoint &_minp, const tripoint &_maxp ) :
            minp( _minp ), maxp( _maxp ) {
        }

        tripoint_range( tripoint &&_minp, tripoint &&_maxp ) :
            minp( _minp ), maxp( _maxp ) {
        }

        point_generator begin() const {
            return point_generator( minp, *this );
        }

        point_generator end() const {
            // Return the point AFTER the last one
            // That is, point under (in z-levels) the first one, but one z-level below the last one
            return point_generator( tripoint( minp.x, minp.y, maxp.z + 1 ), *this );
        }

        size_t size() const {
            tripoint range( maxp - minp );
            return std::max( ++range.x * ++range.y * ++range.z, 0 );
        }

        bool empty() const {
            return size() == 0;
        }

        const tripoint &min() const {
            return minp;
        }
        const tripoint &max() const {
            return maxp;
        }
};

// 2D analog of tripoint_range for any Point type with dimension == 2.
// Iterates all points in [minp, maxp] (inclusive both ends), x-major order.
// Ported from Bright Nights map_iterator.h; needed by coordinates.h
// (submap_tiles() etc.). Our existing tripoint_range above is left untouched.
template<typename Point>
class point_range : public std::ranges::view_interface<point_range<Point>>
{
        static_assert( Point::dimension == 2, "Requires 2D point type" );
    private:
        using traits = point_traits<Point>;

        Point minp;
        Point maxp;

    public:
        class point_generator
        {
                friend class point_range;
            private:
                Point p;
                Point range_min;
                Point range_max;

            public:
                using value_type = Point;
                using difference_type = std::ptrdiff_t;
                using pointer = const Point *;
                using reference = const Point &;
                using iterator_category = std::forward_iterator_tag;
                using iterator_concept = std::forward_iterator_tag;

                point_generator() = default;

                point_generator( const Point &_p, const point_range *_range )
                    : p( _p ) {
                    if( _range ) {
                        range_min = _range->minp;
                        range_max = _range->maxp;
                    }
                }

                // Increment x first; when x exceeds range_max wrap to range_min and increment y.
                auto operator++() -> point_generator & { // *NOPAD*
                    traits::x( p )++;
                    if( traits::x( p ) <= traits::x( range_max ) ) {
                        return *this;
                    }
                    traits::y( p )++;
                    traits::x( p ) = traits::x( range_min );
                    return *this;
                }

                auto operator++( int ) -> point_generator {
                    auto tmp = *this;
                    ++( *this );
                    return tmp;
                }

                auto operator*() const -> reference { return p; }

                auto operator==( const point_generator &other ) const -> bool {
                    return p == other.p;
                }
        };

        using iterator = point_generator;
        using value_type = typename point_generator::value_type;
        using difference_type = typename point_generator::difference_type;
        using pointer = typename point_generator::pointer;
        using reference = typename point_generator::reference;
        using iterator_category = typename point_generator::iterator_category;

        point_range( const Point &_minp, const Point &_maxp ) :
            minp( _minp ), maxp( _maxp ) {}

        auto begin() const -> point_generator {
            return point_generator( minp, this );
        }

        auto end() const -> point_generator {
            // Sentinel: x resets to range_min, y goes one past range_max.
            Point end_p;
            traits::x( end_p ) = traits::x( minp );
            traits::y( end_p ) = traits::y( maxp ) + 1;
            return point_generator( end_p, this );
        }

        auto size() const -> size_t {
            const int w = traits::x( maxp ) - traits::x( minp ) + 1;
            const int h = traits::y( maxp ) - traits::y( minp ) + 1;
            return static_cast<size_t>( std::max( w * h, 0 ) );
        }

        const Point &min() const { return minp; }
        const Point &max() const { return maxp; }
};

// C++20 ranges compatibility verification for point_range
static_assert( std::forward_iterator<point_range<point>::point_generator> );
static_assert( std::ranges::forward_range<point_range<point>> );
static_assert( std::ranges::view<point_range<point>> );

#endif

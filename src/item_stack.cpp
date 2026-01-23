#include "item_stack.h"

#include <algorithm>
#include <list>

#include "item.h"
#include "units.h"

size_t item_stack::size() const
{
    return mystack->size();
}

bool item_stack::empty() const
{
    return mystack->empty();
}

void item_stack::clear()
{
    // An acceptable implementation for list; would be bad for vector
    while( !empty() ) {
        erase( begin() );
    }
}

std::list<item>::iterator item_stack::begin()
{
    return mystack->begin();
}

std::list<item>::iterator item_stack::end()
{
    return mystack->end();
}

std::list<item>::const_iterator item_stack::begin() const
{
    return mystack->cbegin();
}

std::list<item>::const_iterator item_stack::end() const
{
    return mystack->cend();
}

std::list<item>::reverse_iterator item_stack::rbegin()
{
    return mystack->rbegin();
}

std::list<item>::reverse_iterator item_stack::rend()
{
    return mystack->rend();
}

std::list<item>::const_reverse_iterator item_stack::rbegin() const
{
    return mystack->crbegin();
}

std::list<item>::const_reverse_iterator item_stack::rend() const
{
    return mystack->crend();
}

item &item_stack::front()
{
    return mystack->front();
}

item &item_stack::operator[]( size_t index )
{
    return *( std::next( mystack->begin(), index ) );
}

units::volume item_stack::stored_volume() const
{
    units::volume ret = 0_ml;
    for( const item &it : *mystack ) {
        ret += it.volume();
    }
    return ret;
}

long item_stack::amount_can_fit( const item &it ) const
{
    const bool violates_count = size() >= static_cast<size_t>( count_limit() );
    const item *here = it.count_by_charges() ? stacks_with( it ) : nullptr;

    if( violates_count && !here ) {
        return 0l;
    }

    const units::volume fv = free_volume();

    // Base calculation (existing behavior)
    long ret = std::max( 0l, it.charges_per_volume( fv ) );

    if( it.count_by_charges() ) {
        // allow inserting all charges even if charges_per_volume() returns 0
        if( ret == 0l && fv > 0_ml && it.volume() <= fv ) {
            ret = it.charges;
        }
        return std::min( ret, it.charges );
    }

    return ret;
}

item *item_stack::stacks_with( const item &it )
{
    for( item &here : *mystack ) {
        if( here.stacks_with( it ) ) {
            return &here;
        }
    }
    return nullptr;
}

const item *item_stack::stacks_with( const item &it ) const
{
    for( const item &here : *mystack ) {
        if( here.stacks_with( it ) ) {
            return &here;
        }
    }
    return nullptr;
}

units::volume item_stack::free_volume() const
{
    return max_volume() - stored_volume();
}

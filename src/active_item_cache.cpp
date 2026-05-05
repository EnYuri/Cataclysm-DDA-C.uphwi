#include "active_item_cache.h"

#include <algorithm>

#include "debug.h"
#include "item.h"

void active_item_cache::remove( std::list<item>::iterator it, point /*location*/ )
{
    item *const ptr = &*it;
    const auto cit = active_item_set.find( ptr );
    if( cit == active_item_set.end() ) {
        debugmsg( "The item isn't there!" );
        return;
    }
    // The handle records exactly which bucket and list position this item occupies, so
    // removal is O(1) regardless of bucket size or whether processing_speed has changed
    // since the item was added.
    auto bucket_it = active_items.find( cit->second.speed_bucket );
    if( bucket_it != active_items.end() ) {
        bucket_it->second.erase( cit->second.list_it );
    }
    active_item_set.erase( cit );
}

void active_item_cache::add( std::list<item>::iterator it, point location )
{
    item *const ptr = &*it;
    // Reserve a slot up front. If the entry was already present, .second is false and
    // we bail without touching the bucket -- this collapses the previous find()+emplace
    // pair into one hash lookup, which is a measurable win on bulk inserts (vehicle
    // cargo deserialize calls add() once per cargo item).
    auto emplaced = active_item_set.emplace( ptr, cache_handle{} );
    if( !emplaced.second ) {
        return;
    }
    const int speed = it->processing_speed();
    auto &bucket = active_items[speed];
    bucket.push_back( item_reference{ location, it, ptr } );
    emplaced.first->second = cache_handle{ speed, std::prev( bucket.end() ), false };
}

bool active_item_cache::has( std::list<item>::iterator it, point ) const
{
    return active_item_set.find( &*it ) != active_item_set.end();
}

bool active_item_cache::has( const item_reference &itm ) const
{
    const auto found = active_item_set.find( itm.item_id );
    return found != active_item_set.end() && found->second.returned;
}

bool active_item_cache::empty() const
{
    return active_items.empty();
}

// get() only returns the first size() / processing_speed() elements of each list, rounded up.
// It relies on the processing logic to remove and reinsert the items to they
// move to the back of their respective lists (or to new lists).
// Otherwise only the first n items will ever be processed.
std::list<item_reference> active_item_cache::get()
{
    std::list<item_reference> items_to_process;
    for( auto &tuple : active_items ) {
        // Rely on iteration logic to make sure the number is sane.
        int num_to_process = tuple.second.size() / tuple.first;
        for( auto &an_iter : tuple.second ) {
            const auto cit = active_item_set.find( an_iter.item_id );
            if( cit != active_item_set.end() ) {
                cit->second.returned = true;
            }
            items_to_process.push_back( an_iter );
            if( --num_to_process < 0 ) {
                break;
            }
        }
    }
    return items_to_process;
}

void active_item_cache::reserve( size_t n )
{
    active_item_set.reserve( active_item_set.size() + n );
}

void active_item_cache::subtract_locations( const point &delta )
{
    for( auto &pair : active_items ) {
        for( item_reference &ir : pair.second ) {
            ir.location -= delta;
        }
    }
}


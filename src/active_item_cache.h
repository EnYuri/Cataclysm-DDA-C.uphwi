#pragma once
#ifndef ACTIVE_ITEM_CACHE_H
#define ACTIVE_ITEM_CACHE_H

#include <list>
#include <unordered_map>

#include "enums.h"

class item;

// A struct used to uniquely identify an item within a submap or vehicle.
struct item_reference {
    point location;
    std::list<item>::iterator item_iterator;
    // Do not access this from outside this module, it is only used as an ID for active_item_set.
    item *item_id;
};

class active_item_cache
{
    private:
        // Per-item handle into active_items, kept in sync with each insertion / removal.
        // Storing the bucket key + list iterator turns remove() into an O(1) operation
        // instead of a linear scan over the bucket (and a fallback scan over every bucket
        // when the item's processing_speed has changed since insertion).
        struct cache_handle {
            int speed_bucket;
            std::list<item_reference>::iterator list_it;
            // Set to false on add(), set to true the first time get() emits this entry,
            // and cleared only by remove() (which erases the whole entry). It is NOT
            // reset between turns -- "returned" really means "has been emitted by some
            // past get() call", not "was emitted by the most recent one".
            //
            // The flag exists as an address-reuse guard: while a process loop walks a
            // get() snapshot, an item may be remove()d and another item add()ed at the
            // same memory address. The new entry starts with returned=false, so a
            // has(item_reference) check against a stale snapshot ref will correctly
            // skip the slot. Removing this flag would make that race unsafe.
            bool returned;
        };

        std::unordered_map<int, std::list<item_reference>> active_items;
        // Authoritative index for fast membership/lookup. Every entry in active_items has
        // a corresponding entry here, and vice versa.
        std::unordered_map<item *, cache_handle> active_item_set;

    public:
        void remove( std::list<item>::iterator it, point location );
        void add( std::list<item>::iterator it, point location );
        bool has( std::list<item>::iterator it, point ) const;
        // Use this one if there's a chance that the item being referenced has been invalidated.
        bool has( const item_reference &itm ) const;
        bool empty() const;
        std::list<item_reference> get();

        // Pre-size the lookup set to avoid rehashing when bulk-loading (e.g. vehicle cargo).
        void reserve( size_t n );

        /** Subtract delta from every item_reference's location */
        void subtract_locations( const point &delta );
};

#endif

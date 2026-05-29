#pragma once
#ifndef ENCHANTMENT_H
#define ENCHANTMENT_H

#include <string>
#include <vector>

#include "string_id.h"

class JsonObject;
class enchantment;
using enchantment_id = string_id<enchantment>;

enum class enchant_val : int {
    STRENGTH,
    DEXTERITY,
    INTELLIGENCE,
    PERCEPTION,
    SPEED,
    MAX_HP,
    DODGE,
    HIT,
    NUM_TYPES
};

enum class enchant_condition : int {
    ALWAYS,   // active whenever worn/wielded
    ACTIVE,   // active only when item is powered on
    INACTIVE, // active only when item is powered off
    NUM_CONDITIONS
};

struct enchant_entry {
    enchant_val value = enchant_val::STRENGTH;
    int add = 0;
};

class enchantment
{
    public:
        enchantment_id id;
        bool was_loaded = false;

        enchant_condition condition() const {
            return condition_;
        }
        const std::vector<enchant_entry> &values() const {
            return values_;
        }

        int get_value_add( enchant_val val ) const;

        void load( JsonObject &jo, const std::string &src );

        static void load_all( JsonObject &jo, const std::string &src );
        static void reset();
        static const std::vector<enchantment> &get_all();

    private:
        enchant_condition condition_ = enchant_condition::ALWAYS;
        std::vector<enchant_entry> values_;
};

#endif // ENCHANTMENT_H

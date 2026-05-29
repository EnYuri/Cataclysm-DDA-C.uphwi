#pragma once
#ifndef PROFICIENCY_H
#define PROFICIENCY_H

#include <string>
#include <vector>

#include "calendar.h"
#include "string_id.h"

class JsonObject;
class proficiency;
using proficiency_id = string_id<proficiency>;

class proficiency
{
    public:
        proficiency_id id;
        bool was_loaded = false;

        std::string name() const {
            return name_;
        }
        std::string description() const {
            return description_;
        }
        float default_time_multiplier() const {
            return default_time_multiplier_;
        }
        float default_fail_multiplier() const {
            return default_fail_multiplier_;
        }
        time_duration time_to_learn() const {
            return time_to_learn_;
        }
        const std::vector<proficiency_id> &required_proficiencies() const {
            return required_proficiencies_;
        }

        void load( JsonObject &jo, const std::string &src );

        static void load_all( JsonObject &jo, const std::string &src );
        static void reset();
        static const std::vector<proficiency> &get_all();

    private:
        std::string name_;
        std::string description_;
        float default_time_multiplier_ = 2.0f;
        float default_fail_multiplier_ = 1.5f;
        time_duration time_to_learn_ = 0_turns;
        std::vector<proficiency_id> required_proficiencies_;
};

#endif // PROFICIENCY_H

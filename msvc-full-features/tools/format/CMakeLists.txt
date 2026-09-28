include(ExternalProject)

add_executable(json_formatter format.cpp ${CATA_ROOT}/src/json.cpp)

add_definitions(-DCATA_IN_TOOL)

include_directories(${CATA_ROOT}/src)

if (RELEASE)
    if (USE_PREFIX_DATA_DIR)
        install(TARGETS json_formatter RUNTIME)
    else()
        install(TARGETS json_formatter RUNTIME DESTINATION .)
    endif()
endif()

# Custom targets for JSON formatting.
# Note: These targets only work on Unix-like systems with find, grep, xargs

if (UNIX)
    # Get number of CPUs for parallel execution
    cmake_host_system_information(RESULT NPROC QUERY NUMBER_OF_LOGICAL_CORES)

    add_custom_target(style-json
        COMMAND find ${CATA_ROOT}/data -name "\"*.json\"" -print0 |
                grep -z -v "^${CATA_ROOT}/data/names/" |
                xargs -0 -L 1 $<TARGET_FILE:json_formatter>
        DEPENDS json_formatter
        WORKING_DIRECTORY ${CATA_ROOT}
        COMMENT "Formatting all JSON files"
    )

    add_custom_target(style-json-parallel
        COMMAND find ${CATA_ROOT}/data -name "\"*.json\"" -print0 |
                grep -z -v "^${CATA_ROOT}/data/names/" |
                xargs -0 -L 1 -P ${NPROC} $<TARGET_FILE:json_formatter>
        DEPENDS json_formatter
        WORKING_DIRECTORY ${CATA_ROOT}
        COMMENT "Formatting all JSON files in parallel"
    )
endif()

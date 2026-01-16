set(FORK_BASE "C.0")

if(GIT_EXECUTABLE)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" describe --tags --abbrev=0 --match "[0-9]*.[0-9A-Za-z]*"
    OUTPUT_VARIABLE VERSION_TAG
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE TAG_OK
  )

  if(NOT TAG_OK STREQUAL "0" OR VERSION_TAG STREQUAL "")
    # is can reach git but cannot get the tags
    set(VERSION_TAG "${FORK_BASE}")
    set(GIT_SUFFIX "-notag")
  else()
    set(GIT_SUFFIX "")
  endif()

  execute_process(
    COMMAND "${GIT_EXECUTABLE}" log -1 --date=format:%Y%m%d --format=%cd
    OUTPUT_VARIABLE COMMIT_DATE
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  execute_process(
    COMMAND "${GIT_EXECUTABLE}" diff --quiet
    RESULT_VARIABLE WORKTREE_DIRTY
  )
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" diff --cached --quiet
    RESULT_VARIABLE INDEX_DIRTY
  )

  set(VERSION "${VERSION_TAG}_${COMMIT_DATE}${GIT_SUFFIX}")

  if(NOT WORKTREE_DIRTY STREQUAL "0" OR NOT INDEX_DIRTY STREQUAL "0")
    set(VERSION "${VERSION}-female_Emanim")
  endif()
else()
  # if no git found
  set(VERSION_TAG "${FORK_BASE}")
  set(VERSION "${VERSION_TAG}_00000000-nogit")
endif()

configure_file("${SRC}" "${DST}" @ONLY)

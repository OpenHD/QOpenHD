project (GeographicLib-C C)

# Version information
set (PROJECT_VERSION_MAJOR 2)
set (PROJECT_VERSION_MINOR 0)
set (PROJECT_VERSION_PATCH 0)
set (PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}")
if (PROJECT_VERSION_PATCH GREATER 0)
  set (PROJECT_VERSION "${PROJECT_VERSION}.${PROJECT_VERSION_PATCH}")
endif ()
set (PROJECT_VERSION_SUFFIX "")
set (PROJECT_FULLVERSION ${PROJECT_VERSION}${PROJECT_VERSION_SUFFIX})
cmake_minimum_required (VERSION 3.13.0)

set (PACKAGE_DIR "${PROJECT_NAME}-${PROJECT_VERSION}")
set (PACKAGE_NAME "${PROJECT_NAME}-${PROJECT_FULLVERSION}")

option (CONVERT_WARNINGS_TO_ERRORS "Convert warnings into errors?" ON)
option (BUILD_DOCUMENTATION "Use doxygen to create the documentation" ON)
option (BUILD_SHARED_LIBS "Build as a shared library" ON)

# Set a default build type for single-configuration cmake generators if
# no build type is set.
if (NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE Release)
endif ()

# We require C99
set (CMAKE_C_STANDARD 99)
set (CMAKE_C_STANDARD_REQUIRED ON)
set (CMAKE_C_EXTENSIONS OFF)

# Make the compiler more picky.
if (MSVC)
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W4")
else ()
  set (CMAKE_C_FLAGS
    "${CMAKE_C_FLAGS} -Wall -Wextra -Wno-array-bounds -pedantic")
  if (NOT CMAKE_C_COMPILER_ID STREQUAL "Intel")
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wfloat-conversion")
  endif ()
endif ()

# Tell Intel compiler to do arithmetic accurately.  This is needed to
# stop the compiler from ignoring parentheses in expressions like
# (a + b) + c and from simplifying 0.0 + x to x (which is wrong if
# x = -0.0).
if (CMAKE_C_COMPILER_ID STREQUAL "Intel")
  if (MSVC)
    set (CMAKE_C_FLAGS
      "${CMAKE_C_FLAGS} /fp:precise /Qdiag-disable:11074,11076")
  else ()
    set (CMAKE_C_FLAGS
      "${CMAKE_C_FLAGS} -fp-model precise -diag-disable=11074,11076")
  endif ()
endif ()

if (CONVERT_WARNINGS_TO_ERRORS)
  if (MSVC)
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /WX")
  else ()
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror")
  endif ()
endif ()

set (LIBNAME geodc)
if (MSVC OR CMAKE_CONFIGURATION_TYPES)
  # For multi-config systems and for Visual Studio, the debug version of
  # the library is called Geographic_d.
  set (CMAKE_DEBUG_POSTFIX _d)
endif ()
set (TOOLS direct inverse planimeter)

add_subdirectory (src)
add_subdirectory (tools)
add_subdirectory (tests)

enable_testing ()
# Run the test suite
add_test (NAME geodtest COMMAND geodtest)
add_test (NAME signtest COMMAND geodsigntest)

add_custom_target (proj-example
  COMMAND
  ${CMAKE_COMMAND} -B proj-example-build -S ${PROJECT_SOURCE_DIR}/proj-example
  COMMAND cd proj-example-build && make
  COMMENT "Compile sample code linking against PROJ")

# The documentation depends on doxygen.
if (BUILD_DOCUMENTATION)
  set (DOXYGEN_SKIP_DOT ON)
  # Version 1.8.7 or later needed for &hellip;
  find_package (Doxygen 1.8.7)
  if (DOXYGEN_FOUND)
    add_subdirectory (doc)
  else ()
    message (WARNING "Doxygen not found, not building the documentation")
    set (BUILD_DOCUMENTATION OFF)
  endif ()
endif ()

if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/.git AND NOT WIN32)
  add_custom_target (checktrailingspace
    COMMAND git ls-files | xargs grep ' $$' || true
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMENT "Looking for trailing spaces")
  add_custom_target (checktabs
    COMMAND git ls-files | xargs grep '\t' || true
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMENT "Looking for tabs")
  add_custom_target (checkblanklines
    COMMAND git ls-files |
    while read f\; do tr 'X\\n' 'YX' < $$f |
    egrep '\(^X|XXX|XX$$|[^X]$$\)' > /dev/null && echo $$f\; done || true
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMENT "Looking for extra blank lines")

  add_custom_target (sanitize)
  add_dependencies (sanitize checktrailingspace checktabs checkblanklines)
endif ()

# The configuration of CPack is via variables that need to be set before
# the include (CPack).
set (CPACK_PACKAGE_CONTACT charles@karney.com)
set (CPACK_PACKAGE_VENDOR "GeographicLib-C")
set (CPACK_PACKAGE_DESCRIPTION_SUMMARY
  "GeographicLib C library and documentation")
# The list of files to be excluded from the source distribution.
set (CPACK_SOURCE_IGNORE_FILES
  "#"
  "~\$"
  "/\\\\.git"
  "/\\\\.htaccess"
  "${PROJECT_SOURCE_DIR}/doc/.*html"
  "${PROJECT_SOURCE_DIR}/BUILD"
  "${PROJECT_SOURCE_DIR}/distrib-C")
set (CPACK_SOURCE_GENERATOR TGZ)

set (CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set (CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set (CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})

set (CPACK_SOURCE_PACKAGE_FILE_NAME "${PACKAGE_DIR}")
set (CPACK_PACKAGE_INSTALL_DIRECTORY "${PACKAGE_DIR}")

include (CPack)

if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/.git AND NOT WIN32)

  set (DISTRIB_DIR "${CMAKE_BINARY_DIR}/distrib")
  add_custom_target (dist
    COMMAND ${CMAKE_MAKE_PROGRAM} package_source
    COMMAND ${CMAKE_COMMAND} -E
    copy ${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz
    ${DISTRIB_DIR}/${PACKAGE_NAME}.tar.gz
    COMMAND
      cd _CPack_Packages/Linux-Source/TGZ/${CPACK_PACKAGE_INSTALL_DIRECTORY} &&
      find -type f | cut -f2- -d/ | sort > ${DISTRIB_DIR}/package.list &&
      cd ${PROJECT_SOURCE_DIR} &&
      git ls-files | sort > ${DISTRIB_DIR}/git.list &&
      comm -23 ${DISTRIB_DIR}/package.list ${DISTRIB_DIR}/git.list
      > ${DISTRIB_DIR}/unwanted.list &&
      if test -s ${DISTRIB_DIR}/unwanted.list\; then
      echo "WARNING: Unwanted files in source package" &&
      cat ${DISTRIB_DIR}/unwanted.list\; fi &&
      echo "created distrib/${PACKAGE_NAME}.tar.gz")

  find_program (RSYNC rsync)
  if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/distrib-C AND RSYNC)
    set (USER karney)
    set (DATAROOT $ENV{HOME}/web/geographiclib-files/distrib-C)
    set (DOCROOT $ENV{HOME}/web/geographiclib-web/htdocs/C)
    set (FRSDEPLOY ${USER}@frs.sourceforge.net:/home/frs/project/geographiclib)
    set (WEBDEPLOY ${USER},geographiclib@web.sourceforge.net:./htdocs)
    set (PROJDIR $ENV{HOME}/git/PROJ/src)

    add_custom_target (stage-dist
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${DISTRIB_DIR}/${PACKAGE_NAME}.tar.gz ${PROJECT_SOURCE_DIR}/distrib-C/
      COMMAND ${RSYNC} --delete -av --exclude '*~'
        ${PROJECT_SOURCE_DIR}/distrib-C/ ${DATAROOT}/)
    add_dependencies (stage-dist dist)

    if (BUILD_DOCUMENTATION)
      add_custom_target (stage-doc
        COMMAND ${RSYNC} --delete -a doc/html/ ${DOCROOT}/${PROJECT_VERSION}/
        COMMAND cd ${PROJECT_SOURCE_DIR}/doc &&
          ${RSYNC} --delete -av HEADER.html FOOTER.html .htaccess ${DOCROOT}/)
      add_dependencies (stage-doc doc)
    endif ()

    add_custom_target (deploy-dist
      COMMAND ${RSYNC} --delete -av ${DATAROOT} ${FRSDEPLOY}/)
    add_custom_target (deploy-doc
      COMMAND ${RSYNC} --delete -av -e ssh ${DOCROOT} ${WEBDEPLOY}/)
  endif ()

  if (IS_DIRECTORY ${PROJDIR}/tests)
    add_custom_target (stage-proj
      COMMAND
        ${CMAKE_COMMAND} -E copy_if_different src/geodesic.h ${PROJDIR}/ &&
        ${CMAKE_COMMAND} -E copy_if_different src/geodesic.c ${PROJDIR}/ &&
        ${CMAKE_COMMAND} -E copy_if_different
        tests/geodtest.c ${PROJDIR}/tests/geodtest.cpp &&
        ${CMAKE_COMMAND} -E copy_if_different
        tests/geodsigntest.c ${PROJDIR}/tests/geodsigntest.cpp
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      COMMENT "Exporting source to ${PROJDIR}")
  endif ()
endif ()

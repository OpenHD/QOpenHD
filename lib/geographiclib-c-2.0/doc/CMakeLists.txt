configure_file (doxyfile.in doxyfile @ONLY)
configure_file (geodesic-c.dox.in geodesic-c.dox @ONLY)
set (CSOURCES
  ../src/geodesic.h
  ../src/geodesic.c
  ../tools/direct.c
  ../tools/inverse.c
  ../tools/planimeter.c
  )

add_custom_target (doc ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/html/index.html)

add_custom_command (OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/html/index.html
  DEPENDS ${CSOURCES}
    ${CMAKE_CURRENT_BINARY_DIR}/doxyfile
    ${CMAKE_CURRENT_BINARY_DIR}/geodesic-c.dox
  COMMAND ${DOXYGEN_EXECUTABLE} doxyfile > doxygen.log
  COMMENT "Generating C documentation tree")

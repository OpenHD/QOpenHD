set (TESTS geodtest geodsigntest)

if (NOT MSVC)
  set (MATH_LIBS m)
endif ()

foreach (TEST geodtest)
  add_executable (${TEST} ${TEST}.c)
  target_link_libraries (${TEST} ${LIBNAME} ${MATH_LIBS})
endforeach ()

foreach (TEST geodsigntest)
  add_executable (${TEST} ${TEST}.c)
  # geodsigntest includes geodesic.c directly so it doesn't need to link
  # against the library.
  target_link_libraries (${TEST} ${MATH_LIBS})
  target_include_directories (${TEST} PRIVATE ../src)
endforeach ()

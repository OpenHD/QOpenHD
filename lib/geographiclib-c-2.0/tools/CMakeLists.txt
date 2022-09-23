if (NOT MSVC)
  set (MATH_LIBS m)
endif ()

foreach (TOOL ${TOOLS})
  add_executable (${TOOL} ${TOOL}.c)
  target_link_libraries (${TOOL} ${LIBNAME} ${MATH_LIBS})
endforeach ()

if (MSVC OR CMAKE_CONFIGURATION_TYPES)
  # Add _d suffix for your debug versions of the tools
  set_target_properties (${TOOLS} PROPERTIES
    DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
endif ()

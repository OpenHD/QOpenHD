add_library (${LIBNAME} geodesic.c geodesic.h)

target_include_directories (${LIBNAME} PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
  $<INSTALL_INTERFACE:include>)

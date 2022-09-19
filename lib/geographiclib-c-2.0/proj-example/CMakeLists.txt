project (proj-example C)
cmake_minimum_required (VERSION 3.13.0)

find_package (PROJ REQUIRED)

add_executable (proj-example proj-example.c)
target_link_libraries (proj-example ${PROJ_LIBRARIES})

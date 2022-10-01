# add executable
#add_executable(main main.cc)

# link executable to webrtc library
# Since the webrtc library has public include directories
# we will use those link directories when building `main`
#target_link_libraries(main LINK_PUBLIC webrtc)

option(H264NAL_SMALL_FOOTPRINT, "small footprint build")

if(H264NAL_SMALL_FOOTPRINT)
  message(STATUS "src: small footprint selected")
  add_compile_definitions(SMALL_FOOTPRINT)
else()
  message(STATUS "src: normal footprint selected")
  add_compile_definitions(FDUMP_DEFINE)
  add_compile_definitions(RTP_DEFINE)
  add_compile_definitions(FPRINT_ERRORS)
endif()

add_executable(h264nal-bin h264nal.cc)
target_include_directories(h264nal-bin PUBLIC ../src)
target_link_libraries(h264nal-bin PUBLIC h264nal)
# rename executable using target properties
set_target_properties(h264nal-bin PROPERTIES OUTPUT_NAME h264nal)

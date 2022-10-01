# create a library called "libwebrtc" which includes the source
# files "bit_buffer.*".
add_library (webrtc rtc_base/arraysize.h rtc_base/bit_buffer.cc rtc_base/bit_buffer.h)

# Make sure compiler can find include files for our libwebrtc library
# when other libraries or executables link to libwebrtc
target_include_directories (webrtc PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

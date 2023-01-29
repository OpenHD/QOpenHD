Here are all the external libraries for QOpenHD

MAVSDK needs to be built and installed on your system to compile QOpenHD
The other libraries are built and included directly during the QOpenHD compilation process (qmake-compatible).

NOTE on mavlink:

We use a custom mavlink flavour (openhd). However, we also use MAVSDK for QOpenHD, and mavlink comes with MAVSDK by default.
Therefore, we don't have mavlink as a submodule here, but rather MAVSDK.

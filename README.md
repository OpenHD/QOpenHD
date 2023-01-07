# QOpenHD

QOpenHD is the default OpenHD companion app that runs on the OHD Ground station or any other "external" devices connected to the ground station.

It is responsible for displaying the (main) video stream to the user, composed with the OSD and changing OpenHD settings.

As the name suspects, it is based on QT (5.15.X).

![temporary_screenshot](https://github.com/OpenHD/QOpenHD/blob/2.2.3-evo/wiki/temporary_screenshot.png)

# Compiling:
We have a CI setup that checks compilation on ubuntu. You can look at the steps it performs to build and run QOpenHD.
Other platforms than Linux are not supported right now.

# Developer Design Overview (incomplete)
1) QOpenHD is not OpenHD (main). It can talk to a running OpenHD main instance (ground and/or air) via Mavlink and rceives the (primary / secondary / ++) video streams. 
2) While QOpenHD is the default companion app, OpenHD MUST NOT assume there is a QOpenHD instance somewhere that initiates voodo settings / setup processes
( This is in contrast to OpenHD /QOpenHD releases before the "evo" series.) As a result of this limitation, Both OpenHD and QOpenHD can be developed independently from each other, and debugging becomes a lot easier.

# MavSDK
QOpenHD relies on MavSDK library. After recursively cloning qopenhd build this library:

`cd lib/MAVSDK`

`cmake -Bbuild/default -DCMAKE_BUILD_TYPE=Release -H.`

`cmake --build build/default -j4`

`sudo cmake --build build/default --target install`

After that, you can build QOpenHD by either opening it in QT Creator (recommended) or building it with the following commands:

`mkdir build`
`cd build`
`qmake ..`

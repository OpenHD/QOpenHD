## QOpenHD

![OSD](https://raw.githubusercontent.com/infincia/QOpenHD/master/wiki/osd.jpg)

This is a companion app for the Open.HD drone platform, including digital FPV display in-app, along with support for changing ground station settings and gamepad/joystick support.

The code is functional but very new, more of a technical preview than an alpha or beta in terms of features, but it should still be *stable* in that it shouldn't crash or have weird glitchy behavior.

## State of the code

### ***There are bugs, but they'll all be fixed rapidly***.

For example: 

* The downlink RSSI occasionally shows zero on some platforms
* [Video is horribly delayed](https://github.com/infincia/QOpenHD/issues/1) on some (all?) Android devices
* [Some settings don't save properly](https://github.com/infincia/QOpenHD/issues/2)
* [Not all settings show up](https://github.com/infincia/QOpenHD/issues/8) if there is high CPU load or RF interference (simple fix on GroundPi)

Some of those are bugs on the GroundPi side (mostly code nobody has ever "exercised" before) or require small changes to the Open.HD image, others are just things I haven't fixed yet in the app.

However, as of the `v0.1` tag the app itself should run the same on every platform. I have not even tried to run it on Linux or Windows though, so there may be some build script changes needed there.

Things like RC and video rendering are inherently dependent on platform support to some extent. For example, iOS is never going to support USB connected joysticks or TX, but will support things like bluetooth gamepads if the GroundPi is 5.8Ghz (the interference is **horrible** and easily noticed if the GroundPi is 2.4Ghz, stick movements have huge lag). 

| Feature | GroundPi | Windows | Mac | Linux | Android | iOS | 
| --- | --- | --- | --- | --- | --- | --- |
| Video | Yes | Untested | Yes | Untested | High Latency | Yes |
| Settings | Partial | Partial | Partial | Partial | Partial | Partial |
| RC | Yes | Disabled | Disabled | Disabled | Disabled | Disabled |
| Backlight Control | N/A | N/A | N/A | N/A | N/A | Yes |
| Mavlink | Yes | Yes | Yes | Yes | Yes | Yes |
| FRSky | No | No | No | No | No | No |
| MSPv2 | No | No | No | No | No | No |
| Voice Feedback | Yes | Yes | Yes | Yes | Yes | Yes |


RC handling in the app is only disabled temporarily for safety, it will be supported everywhere once fully implemented and tested.

Settings are only "partial" supported because there are some bugs on the GroundPi side (likely `RemoteSettings.py`) that affect certain settings. The values dont make it into the `openhd-settings-1.txt` file intact, which corrupts the file and causes the GroundPi to stop booting properly. I haven't had a chance to find and fix that yet, so only specific settings can be saved (the ones in the named tabs, not "other"). Otherwise settings basically works fine everywhere.

## Platforms

The code is mostly C++ and uses the Qt framework, specifically QtQuick which is designed for portability and renders using OpenGL.

This allows the same app to run on Windows, Mac, Linux, iOS, and Android, as well as directly on the GroundPi itself (either using the official touchscreen or an HDMI screen + mouse).

## Code architecture

The core is C++ (in `src`), and the UI is designed with QtQuick, which is a declarative UI framework. You can find the UI files in `qml`.

QtQuick is designed to be an MVC code architecture, and QOpenHD follows that pattern for the most part. The UI layer is separated into declarative UI "forms" with a matching logic-only layer under them, you can see that in the file names for most of the components (there will be a -Form.qml for each one).

There is a small amount of "glue" code in the QML layer, the language is basically Javascript but desigend to integrate with QML.

## Widgets

There are currently a small number of simple OSD widgets in static locations on the upper and lower overlay bars. 

They can be enabled/disabled individually in settings, but not moved yet.

The widgets are going to be drag-and-drop in the near future, and will be presented on a grid so they can be placed anywhere on screen rather than only the upper and lower bars.

## Telemetry

The Open.HD telemetry is handled via UDP when the app is running on a phone or a computer, and via the same shared memory system used by the original OSD when running on GroundPi.

For vehicle telemetry, only Mavlink is supported at the moment but only because it's what I use and can test with easily.

Some minor refactoring (turn `MavlinkTelemetry.cpp` into a subclass) is needed to support other telemetry protocols but there is otherwise no reason they can't work.

## Settings

![Ground Pi Radio Settings](https://raw.githubusercontent.com/infincia/QOpenHD/master/wiki/settings-radio.png)

The app has a full touch interface for GroundPi settings, including radio frequency, video resolution and bitrate, the Wi-Fi and Ethernet hotspot settings, etc.

Some settings are treated specially and presented in a specific tab. This allows them to use appropriate UI controls and to limit the possible choices where that makes sense.

However *all* settings, including any new settings added to the GroundPi in the future, can be changed from the app. This does not require an app update, the new settings will simply show up in the "other" tab with a plain text editing field ensuring they can be changed no matter what the value is supposed to be. Just be careful not to break anything by entering the wrong value in those fields :)

## RC

This is currently disabled via compiler flag to prevent anyone from using it and accidentally causing a flyaway or getting injured. The code is not yet finished and has a few bugs to resolve before it can be trusted.

This is not an issue on the GroundPi because the ground station itself handles joysticks/RC rather than the QOpenHD app.

## Video streaming

On the GroundPi, the app is simply an overlay on `hello_video` just like the original OSD, so video should work exactly the same as it always has.

On other platforms, QtGStreamer is used to decode and render the video stream using available hardware decoders and OpenGL. This is the same code that QGroundControl uses at the moment.

The QtGStreamer code itself is very old and mostly unmaintained upstream, it is likely to be replaced very soon with another video component based on qmlglsink or one based on libavcodec + GL shader rendering that I have been working on.

On Android there seem to be some hardware acceleration issues with the currently committed QtGStreamer code. QGroundControl has a newer version of it where they have implemented hardware acceleration on Android, but it didn't actually work on my test device (the `androidmedia` GStreamer plugin can't be loaded, so the accelerated decoders are not avalable).

Video should be working fine on iOS, Mac, Windows and Linux, as most machines can handle software decoding without trouble (it works, it's just not efficient and wastes battery power).

## Building

I am planning to provide binaries and GroundPi images so that building the app is not necessary, and to ensure that the correct versions of Qt and Gstreamer are available, however if you still want to build it yourself, you can.

These are only a rough outline rather than exhaustive build steps (that would fill several pages and be very complciated to write and keep updated).

The build process is dependent on which platform you're building *on* and which platform you're building *for*. It can be quite complicated and irritating when something doesn't work right, or if you aren't familiar with all these development frameworks and toolchains.

This will be *far* less complicated once QtGStreamer is replaced.

In general, you'll need Qt 5.13.1+ and the GStreamer development package, specifically version 1.16.1 (which seems to handle video packet corruption much better than 1.14.4 does).

#### Mac

1. Install Xcode from the Mac App Store.

2. Install Qt using the [Qt online installer](https://www.qt.io/download-qt-installer)

3. Have the Qt Installer download Qt 5.13.1+ and Qt Creator

4. Download the [GStreamer development kit](https://gstreamer.freedesktop.org/download/), both the Runtime and Development packages.

Once you have those installed you can open `QOpenHD.pro` with Qt Creator, build and run it.

#### Windows

I haven't tried building on Windows yet, but it should be largely identical to the Mac instructions, except you'll need Visual Studio rather than Xcode, and building code on Windows can be complex if you aren't familiar with the process.

I will update these instructions once I have a chance to try it.

#### Linux

Also untested, but you should only need to install Qt either from your distribution repo (if the Qt version they provide is new enough), or using the [Qt online installer](https://www.qt.io/download-qt-installer). You also need to install `gcc`/`binutils`/etc, `gstreamer-1.0`, and related gstreamer development packages from your distribution repo. 

You can then open `QOpenHD.pro` using Qt Creator, build and run the app.

#### Android

1. Install [Android Studio](https://developer.android.com/studio)

2. Use Android Studio to install Android SDK level 28, along with NDK r18b and build toolchain.

3. Install Qt using the [Qt online installer](https://www.qt.io/download-qt-installer)

4. Have the Qt Installer download Qt 5.13.1+ for Android 

5. Download the [GStreamer development kit](https://gstreamer.freedesktop.org/download/) for Android 1.16.1

6. Unzip the GStreamer archive inside the QOpenHD directory.

You can then open `QOpenHD.pro` using Qt Creator and set up the Android kit (left side of the Projects tab), build and run the app on your device.

I have never tried to run it on a simulator, I doubt it would work very well (particularly GStreamer).

#### GroundPi

This is going to be handled automatically by the [Open.HD image builder](https://github.com/HD-Fpv/Open.HD_Image_Builder) as it is very complicated to get right.

It requires a very specific set of packages to be preinstalled on the image, and requires building Qt from source to enable `eglfs`. 

These changes are done and working great, but not pushed to Github yet.

Gstreamer is not involved at all since the app itself doesn't handle the video stream.

I will be publishing complete Open.HD SD card images with QOpenHD integrated properly.

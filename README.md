# QOpenHD

QOpenHD is the default OpenHD companion app that runs on the OHD Ground station or any other "external" devices connected to the ground station.

It is responsible for displaying the main video stream to the user, composed with the OSD, and changing OpenHD settings.

As the name suggests, it is based on QT (5.15.X) and will not run on older versions.

![temporary_screenshot](https://1945119839-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F8RIMU39m4Gt1vqzzt4lm%2Fuploads%2Fgit-blob-353dff94866ae2d4a81fa3329bf93290a0271b42%2FNorbertScreenshot.png?alt=media)

## Developer Design Overview (incomplete)

1. QOpenHD is not OpenHD (main). It can communicate with a running OpenHD main instance (ground and/or air) via Mavlink and receives the (primary / secondary / ++) video streams.
2. While QOpenHD is the default companion app, OpenHD MUST NOT assume there is a QOpenHD instance somewhere that initiates voodoo settings / setup processes. This is in contrast to OpenHD/QOpenHD releases before the "evo" series. As a result of this limitation, both OpenHD and QOpenHD can be developed independently from each other, making debugging easier.

## Installing

Like every OpenHD app or module, we publish packages into our [Cloudsmith Repository](https://cloudsmith.io/~openhd/repos/openhd-2-3-evo/). There are Packages for X86 (ubuntu 22.04,23.04), armhf (rpi, arm64 rockchip). Android releases are available on the Playstore and can be downloaded from there.

## Compiling

We have a CI setup that checks compilation on Ubuntu. You can review the steps it performs to build and run QOpenHD. Other platforms than Linux are not supported at the moment.

### Building QOpenHD Locally in QT (CURRENTLY UNDER DEVELOPMENT)

#### Mac

1. Install Xcode from the Mac App Store.
2. Install Qt using the [Qt online installer](https://www.qt.io/download-qt-installer).
3. Download Qt 5.15.0+ for Mac and Qt Creator using the Qt Installer.
4. Clone the source code:

    ```
    git clone --recurse-submodules https://github.com/OpenHD/QOpenHD.git
    ```

    If you use a GUI git client, ensure you update the submodules or QOpenHD won't build properly.

#### iOS

1. Install Xcode from the Mac App Store.
2. Install Qt using the [Qt online installer](https://www.qt.io/download-qt-installer).
3. Download Qt 5.15.0+ for iOS and Qt Creator using the Qt Installer.
4. You'll need an Apple developer membership to install directly on an iOS device.
5. Clone the source code as mentioned earlier.

#### Windows (CURRENTLY UNDER DEVELOPMENT)

1. Install Visual Studio 2019 (free).
2. Install Qt using the [Qt online installer](https://www.qt.io/download-qt-installer).
3. Download Qt 5.15.0+ and Qt Creator using the Qt Installer.
4. Download the [GStreamer development kit](https://gstreamer.freedesktop.org/download/) for Windows, both the Runtime and Development packages (32-bit MinGW packages, version 1.14.4). QT will look for gstreamer in c:/gstreamer/1.0/x86.
5. Clone the source code as mentioned earlier.

#### Linux

**QTCreator**

1. Install Qt using the [Qt online installer](https://www.qt.io/download-qt-installer).
2. Have it download Qt 5.15.0+ for Linux.
3. Install GStreamer development packages from the package manager (e.g., on Ubuntu, run `apt install gstreamer1.0-gl libgstreamer1.0-dev libgstreamer-plugins-good1.0-dev gstreamer1.0-plugins-good libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-qt`).
4. Clone the source code as mentioned earlier.

### Manual via qmake

1. Clone the source code.
2. Run 'bash install_build_dependencies.sh ARCHITECTURE' (ARCHITECTURE can be X86, rpi, rock5).
3. Run 'build_qmake.sh'.
4. Find the binary under build/releases/QOpenHD.

#### Android

1. Install [Android Studio](https://developer.android.com/studio).
2. Install Android SDK level 28 and NDK r18b using Android Studio.
3. Install Qt using the [Qt online installer](https://www.qt.io/download-qt-installer).
4. Download Qt 5.15.0+ for Android (not for the OS you're building on).
5. Clone the source code as mentioned earlier.

### Building QOpenHD

Step 1) clone this repository with --recurse-submodules
Step 2) install all dependencies 
Step 3) recommended - open in QT creator. Otherwise, you can build QOpenHD via the command line:
```
mkdir build
cd build
qmake ..
```

## Contributing

**Thanks to all the people who have contributed !**

![Contributors](https://fra1.digitaloceanspaces.com/openhd-images/uploads/QOpenHD.svg)

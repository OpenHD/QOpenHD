Here are all the external libraries for QOpenHD

NOTE on mavlink:

We use a custom mavlink flavour (openhd). However, we also use MAVSDK for QOpenHD.
Therefore, we don't have mavlink as a submodule here, but rather MAVSDK.
For development, you have to build and install MAVSDK (which is configured to fetch the openhd mavlink flavour), then you can build QOpenHD.
See the install_dep_ubuntu20.sh and the CI from github.

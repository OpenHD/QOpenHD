rm -rf build

mkdir build

cd build

#qmake ..
./../../../../opt/Qt5.15.4/bin/qmake ..

make -j4

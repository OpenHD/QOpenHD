How to:
1. Create folder `build-libs-windows` in repository root
2. Download and extract a 64-bit shared FFmpeg development build into `build-libs-windows`.
   The CI workflow uses the pinned LGPL build from https://github.com/BtbN/FFmpeg-Builds/releases.
3. Rename extracted folder to `ffmpeg`. Chech that `ffmpeg` folder contains `bin`, `include`, etc. folders.
4. Trying to use prebuild angle from https://github.com/mmozeiko/build-angle
   Download latest release and extract to `build-libs-windows`.
   Maybe it better to clone/adjust this build pipeline

5. After build you need to copy `bin` folders content to folder with `.exe`

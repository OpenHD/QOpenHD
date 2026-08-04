How to:
1. Create folder `build-libs-windows` in repository root
2. Download and extract a shared FFmpeg development build matching the Qt architecture into `build-libs-windows`.
   The 32-bit CI workflow uses the pinned LGPL build from https://github.com/sudo-nautilus/FFmpeg-Builds-Win32/releases.
3. Rename extracted folder to `ffmpeg`. Chech that `ffmpeg` folder contains `bin`, `include`, etc. folders.
4. Trying to use prebuild angle from https://github.com/mmozeiko/build-angle
   Download latest release and extract to `build-libs-windows`.
   Maybe it better to clone/adjust this build pipeline

5. After build you need to copy `bin` folders content to folder with `.exe`

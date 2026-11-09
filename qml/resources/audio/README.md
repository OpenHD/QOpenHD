# Albatross startup sound

Source: `Albatross_Startup_NEW.mp3`, supplied by the user on 2026-11-09.
The bundled `albatross_startup.pcm` is signed 16-bit little-endian PCM at
48000 Hz, stereo (5.758 seconds). Both startup and Test sound use this clip.
The welcome sound toggle and announcement volume still apply.

Decoded once for reliable playback without platform MP3 codec requirements:

```sh
ffmpeg -i Albatross_Startup_NEW.mp3 -vn -acodec pcm_s16le -ar 48000 -ac 2 -f s16le albatross_startup.pcm
```

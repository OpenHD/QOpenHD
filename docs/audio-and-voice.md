# Audio and announcements

Open Application (gear) > General and enable Show advanced settings. The speaker
icon in the left sidebar opens Audio. No developer unlock is needed for this.

Audio contains Sounds & Speech and Voice Rules tabs. Welcome sound, warning
sounds, voice enable, language, speed, volume and tests are on Sounds & Speech.
OpenHD > Extras > Audio retains the incoming stream input/output controls.

Voice Rules is a compact list of presets. Enable a preset directly or press Edit
to change the trigger and phrase. Each editor opens separately; Save applies the
changes and Cancel discards them. Messages can be filtered by text. Telemetry
sources are battery percent, wind in knots, relative altitude in meters and ground
speed in km/h. Phrases accept {value}, {unit} and {message}. Standard phrases and
unit words follow the speech language; custom text and received messages are not
translated automatically. Thresholds speak once until recovery; timed readings
require fresh telemetry. Cooldowns and deduplication limit repeated alerts.

English, German and Spanish are selectable. Windows renders installed native
voices to PCM. Linux can render with eSpeak NG. Other native speech backends are
used through Qt TextToSpeech where available. A missing language voice is
reported, never silently replaced by a different language. Install missing
voices through the operating system's speech settings (or espeak-ng on Linux).
Native Qt speech engines use their system speech output; rendered PCM follows the
selected stream output and is mixed with it. The PCM path uses Qt Multimedia
without GStreamer, or the shared GStreamer mixer when that backend is selected.

Validation: Qt 5 and Qt 6 page interactions, 480px card geometry, language
selection, and native Windows sound/English/German speech without GStreamer.
This Windows installation has no Spanish voice; the missing-voice path is tested.
Linux GStreamer and Qt 6 native code are compile-checked. Playback on other
operating systems and Raspberry Pi hardware remains to be validated.

Native PCM playback prefers 48 kHz stereo. A thread-safe pull mixer supplies
continuous, frame-aligned PCM on the audio backend schedule, with silence for
missing stream packets, linear sample-rate conversion, and saturating mixing.
It does not use a UI-thread pump timer. Continuity, clipping and UI-busy reads
are covered by the native audio tests.

The startup clip is the user-supplied Albatross_Startup_NEW.mp3, bundled as
decoded 48 kHz stereo PCM. Both automatic startup and Test sound use it; the
welcome toggle and announcement volume apply as before. No MP3 codec is needed
on the target system. The original MP3 is retained beside the bundled PCM asset.

Windows and Android show the bundled Albatross animation with this soundtrack.
Windows activates its native window once after exposure, so the introduction
opens in front of the launcher. It does not stay on top or reactivate later.

Hold the centre of the HUD map (or the aircraft marker) to toggle a minimal map
at half the configured width and height. The minimal view hides the zoom buttons
and renders ADS-B aircraft markers at half size. Hold again to restore normal
size and its controls. Map shape, zoom and configured
size are preserved. Double-click continues to toggle the expanded map.

The ADS-B traffic widget toggles a compact single-row view with a centre hold.
It shows only the nearest aircraft's callsign and distance, retaining aircraft
and border warning colours. Short clicks still open traffic details; edge holds
retain the existing placement and customisation controls.

Map and ADS-B minimal modes are saved independently and synchronised to disk
when toggled. Both restore after restarting the app or device. A native test
opens a second process immediately after toggling to verify this restoration.

Long-press the bottom link bar outside its central flight-mode/arming area to
open its style and slot settings. Scroll to Left 1–4 and Right 1–4 to choose GPS
Speed, battery values, altitude and other telemetry fields. Disable
Hide N/A in this editor to show slots while their telemetry is unavailable.

Satellites are permanently visible at the right edge of the bottom bar, outside
the configurable slots. Click the count to toggle a single-line coordinate
callout above the bar, using its font and colours, an accent edge and a pointer
aligned to the satellite icon. Coordinates include degrees and N/S/E/W;
the callout width follows the text with a small fixed gap and padding.
Hold it to open bar settings. Coordinates require a current aircraft GPS fix and
respect the existing identity-offset setting. The standalone GPS widget is off
by default and can still be enabled from the widget gallery.
The satellite icon has a highlight ring while the callout is open. Its open/closed
state is saved immediately and restored after restarting the app. Hiding the
HUD or opening bar settings does not change this saved state.
Callout background opacity, background colour, text, accent, font, text size and
scale follow the bottom bar's style; it has no independent appearance settings.
The map scales both ADS-B markers and our aircraft symbol down by half in minimal
mode, retaining the aircraft marker's normal touch target.

Map and ADS-B start in minimal mode by default; later toggles retain the user's
choice. The map's default anchor is now bottom-right above the GPS callout, with
clearance for its compass labels and the standard altitude ladder. Existing
factory top-right placements migrate; custom placements remain unchanged.

For a temporary visual GPS preview, launch with `--gps-preview`. The callout
and map show a sample position and 12 satellites when real GPS is unavailable;
the window title identifies the preview. No live telemetry fields or positions
are modified or saved, and normal launches do not enable this preview.

The map's cyan aircraft trail records valid, live GPS positions only while
armed. It samples complete coordinate pairs at 5 Hz, ignores movement below
3 metres, and bounds the number of points through gradual simplification. The
completed trail remains after disarming and clears on the next arm. The existing
Map > Show drone track setting controls visibility and recording.

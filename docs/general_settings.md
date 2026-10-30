# Application General

General has three sections: Language, Units, and Text to Speech.

- Language uses the existing English/German translations and restart notice. Flags are local SVGs.
- Metric preserves metric distance, speed and altitude. Imperial uses the existing imperial conversions.
- Hybrid uses metric distance/speed and altitude in feet, including both altitude widgets, the HUD bottom bar and ADS-B altitude labels. Unit samples demonstrate formatting; they are not telemetry.
- Speech voices come from the installed Qt speech engine. Voice, rate (50-200%) and volume (0-100%) are saved locally and applied to the native engine. No-engine builds show an unavailable explanation and disable the controls. Windows includes SAPI when its Qt kit supplies TextToSpeech; deployment includes its DLL/plugin. Qt 6 uses the optional TextToSpeech target when installed.

Animation smoothing is under OSD > Style > Effects & appearance, with the existing 0-1000 ms range. Changes persist immediately, and Reset to default restores 33 ms.

The remaining former General controls (advanced-button visibility, Ground battery cells, QOpenHD system ID and GPS offsets) remain accessible under the hidden Application Developer tab.

Verification: the General Qt tests exercise settings writes, speech adapter calls, language/restart handling and responsive layouts. Style tests cover immediate smoothing persistence. Tests use a mock voice engine and do not prove audible output on hardware.

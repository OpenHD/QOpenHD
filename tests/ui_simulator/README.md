# UI simulator checks

The popup tests use the production QML with a deterministic controller fixture:

```
qmltestrunner -input tests/ui_simulator -platform offscreen
```

`smoke.cpp` tests the native simulator and its isolated parameter models, transport guards,
camera enable/format changes, link edits, allocation, synthetic scan/analysis, storage,
and restoration of original context objects. It also renders the actual popup against
native models. It uses a separate test application identity.

After building QOpenHD with Qt 5 MinGW 32-bit:

```
py -3.12 tests/ui_simulator/run_native_smoke.py --build-dir build/Desktop_Qt_5_15_19_MinGW_32_bit-Release
```

The runner reuses existing application objects and links a separate test executable;
it does not replace the user's QOpenHD executable or modify a device.

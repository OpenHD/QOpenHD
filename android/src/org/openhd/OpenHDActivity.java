package org.openhd;

import android.app.Activity;

import android.content.Context;

import org.qtproject.qt5.android.bindings.QtActivity;
import org.qtproject.qt5.android.bindings.QtApplication;

public class OpenHDActivity extends QtActivity {
    private static OpenHDActivity _instance = null;

    private static native void nativeInit();

    public OpenHDActivity() {
        _instance = this;
    }

    public void onInit(int status) {}

    public static void jniOnLoad() {
        nativeInit();
    }
}

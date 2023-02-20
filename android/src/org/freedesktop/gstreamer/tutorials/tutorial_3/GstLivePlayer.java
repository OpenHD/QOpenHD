package org.freedesktop.gstreamer.tutorials.tutorial_3;

import android.content.Context;
import android.view.Surface;
import android.widget.Toast;

import org.freedesktop.gstreamer.GStreamer;

public class GstLivePlayer {
    static {
        System.loadLibrary("gstreamer_android");
        //System.loadLibrary("tutorial-3");
        nativeClassInit();
    }

    private native void nativeInit();     // Initialize native code, build pipeline, etc
    private native void nativeFinalize(); // Destroy pipeline and shutdown native code
    private native void nativePlay();     // Set pipeline to PLAYING
    private native void nativePause();    // Set pipeline to PAUSED
    private static native boolean nativeClassInit(); // Initialize native class: cache Method IDs for callbacks
    private native void nativeSurfaceInit(Object surface);
    private native void nativeSurfaceFinalize();
    private long native_custom_data;      // Native code will use this to keep private data

    public void xx_init(Context context){
        try {
            GStreamer.init(context);
        } catch (Exception e) {
            Toast.makeText(context, e.getMessage(), Toast.LENGTH_LONG).show();
            return;
        }
        nativeInit();
    }

    public void xx_set_surface_out(Surface video_surface){
        nativeSurfaceInit (video_surface);
    }

    public void xx_remove_surface_out(){
        nativeSurfaceFinalize ();
    }

    public void xx_finalize(){
        nativeFinalize();
    }

    // Called from native code. Native code calls this once it has created its pipeline and
    // the main loop is running, so it is ready to accept commands.
    private void onGStreamerInitialized () {
        // Restore previous playing state
        nativePlay();
    }
}

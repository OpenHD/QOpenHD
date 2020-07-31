package com.openhd.android;

import android.graphics.SurfaceTexture;

public class SurfaceTextureListener implements SurfaceTexture.OnFrameAvailableListener {
    private final long m_id;

    public SurfaceTextureListener(long id) {
        m_id = id;
    }

    @Override
    public void onFrameAvailable(SurfaceTexture surfaceTexture) {
        notifyFrameAvailable(m_id);
    }

    private static native void notifyFrameAvailable(long id);
}

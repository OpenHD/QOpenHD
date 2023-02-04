package org.openhd;

import android.graphics.SurfaceTexture;

public class SurfaceTextureListener implements SurfaceTexture.OnFrameAvailableListener
{
    private long m_callback = 0;

    public SurfaceTextureListener(long callback)
    {
        m_callback = callback;
    }

    @Override
    public void onFrameAvailable (SurfaceTexture surfaceTexture)
    {
        // call the native method
        frameAvailable(m_callback, surfaceTexture);
    }

    public native void frameAvailable(long nativeHandle, SurfaceTexture surfaceTexture);
}

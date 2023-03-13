package org.openhd;

import android.media.MediaPlayer;
import android.view.Surface;
import android.graphics.SurfaceTexture;

import java.io.IOException;

//import org.freedesktop.gstreamer.tutorials.tutorial_3.GstLivePlayer;

public class LiveVideoPlayerWrapper {

    private final MediaPlayer mMediaPlayer=new MediaPlayer();

    //private final GstLivePlayer m_live_player=new GstLivePlayer();

    //public void x_on_create(Context c){
        //m_live_player.xx_init(c);
    //}
    private Surface mSurface=null;

    public void setSurfaceTexture(SurfaceTexture st){
        mSurface=new Surface(st);
        setSurface(mSurface);
    }

    public void setSurface(Surface surface){
        mMediaPlayer.setSurface(surface);
    }

    public void playUrl(String url){
        mMediaPlayer.stop();
        mMediaPlayer.reset();
        try {
            mMediaPlayer.setDataSource(url);
            mMediaPlayer.prepare();
            mMediaPlayer.start();
            mMediaPlayer.setLooping(true);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void releaseAll(){
        mMediaPlayer.stop();
        mMediaPlayer.reset();
        mMediaPlayer.release();
    }
}

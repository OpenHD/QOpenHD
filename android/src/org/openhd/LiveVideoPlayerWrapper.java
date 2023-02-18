package org.openhd;

import android.media.MediaPlayer;
import android.view.Surface;

import java.io.IOException;

public class LiveVideoPlayerWrapper {

    private final MediaPlayer mMediaPlayer=new MediaPlayer();

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

package org.openhd;

import android.app.Activity;

import android.content.Context;

import org.qtproject.qt.android.bindings.QtActivity;

// Custom video surface begin
import android.os.Bundle;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
// Custom video surface end

public class QOpenHDActivity extends QtActivity {
    private static QOpenHDActivity _instance = null;

    private static native void nativeInit();

    private SurfaceView surfaceView=null;

    public QOpenHDActivity() {
        _instance = this;
    }

    public void onInit(int status) {}

    public static void jniOnLoad() {
        nativeInit();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Init surface
        /*surfaceView = new SurfaceView(this);
        surfaceView.setBackgroundColor(0xff0000);
        surfaceView.setZOrderOnTop(false);

        FrameLayout frameLayout=new FrameLayout(this);
        frameLayout.addView(surfaceView,0);*/

        // It displaces original QML view.
        //setContentView(surfaceView);

        // Add SurfaceView to view container
        /*View view = getWindow().getDecorView().getRootView();
        RelativeLayout mainLinearLayout = (RelativeLayout)(((ViewGroup)view).getChildAt(0));
        FrameLayout mainFrameLayout = (FrameLayout)(mainLinearLayout.getChildAt(1));
        mainFrameLayout.addView(surfaceView, 0);*/
        /*ViewGroup viewGroup = (ViewGroup) getWindow().getDecorView().getRootView();
        View view = viewGroup.getChildAt(0);
        view.setPadding(0, 150, 0, 0);

        frameLayout.addView((View)view.getParent(),1);

        setContentView(frameLayout);*/



    }
}

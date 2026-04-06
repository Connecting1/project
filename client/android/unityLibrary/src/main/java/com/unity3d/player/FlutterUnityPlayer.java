package com.unity3d.player;

import android.content.Context;

public class FlutterUnityPlayer extends UnityPlayer {

    public FlutterUnityPlayer(Context context, IUnityPlayerLifecycleEvents lifecycleEvents) {
        super(context, lifecycleEvents);
    }

    public void pause() { onPause(); }
    public void resume() { onResume(); }
    public void start() { onStart(); }
    public void stop() { onStop(); }
    public void focusChanged(boolean hasFocus) { windowFocusChanged(hasFocus); }
}

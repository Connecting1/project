package com.unity3d.player

import android.content.res.Configuration
import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity

open class FlutterUnityActivity : FlutterActivity(), IUnityPlayerLifecycleEvents {

    var mUnityPlayer: FlutterUnityPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mUnityPlayer = FlutterUnityPlayer(this, this)
    }

    override fun onDestroy() {
        mUnityPlayer?.destroy()
        super.onDestroy()
    }

    override fun onStop() {
        super.onStop()
        mUnityPlayer?.stop()
    }

    override fun onStart() {
        super.onStart()
        mUnityPlayer?.start()
    }

    override fun onPause() {
        super.onPause()
        mUnityPlayer?.pause()
    }

    override fun onResume() {
        super.onResume()
        mUnityPlayer?.resume()
    }

    override fun onUnityPlayerUnloaded() {
        moveTaskToBack(true)
    }

    override fun onUnityPlayerQuitted() {}

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        mUnityPlayer?.focusChanged(hasFocus)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        mUnityPlayer?.configurationChanged(newConfig)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_MULTIPLE) {
            return mUnityPlayer?.injectEvent(event) ?: false
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean =
        mUnityPlayer?.onKeyUp(keyCode, event) ?: false

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean =
        mUnityPlayer?.onKeyDown(keyCode, event) ?: false

    override fun onTouchEvent(event: MotionEvent): Boolean =
        mUnityPlayer?.onTouchEvent(event) ?: false

    override fun onGenericMotionEvent(event: MotionEvent): Boolean =
        mUnityPlayer?.onGenericMotionEvent(event) ?: false
}

package com.ofthewolf.aubiotuner

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

class FlutterStreamHandler: EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    private val handler: Handler by lazy {
        Handler(Looper.getMainLooper())
    }
    override fun onCancel(p0: Any?) {
        eventSink = null
    }

    override fun onListen(p0: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    fun sendEventStream(event: Any){
        handler.post { eventSink?.success(event) }
    }

}
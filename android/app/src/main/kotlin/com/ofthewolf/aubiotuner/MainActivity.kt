package com.ofthewolf.aubiotuner

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioRecord
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.annotation.RequiresPermission
import androidx.core.app.ActivityCompat
import be.tarsos.dsp.AudioProcessor
import be.tarsos.dsp.filters.HighPass
import be.tarsos.dsp.filters.LowPassFS
import be.tarsos.dsp.io.android.AudioDispatcherFactory
import be.tarsos.dsp.pitch.PitchDetectionHandler
import be.tarsos.dsp.pitch.PitchProcessor
import be.tarsos.dsp.pitch.PitchProcessor.PitchEstimationAlgorithm
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {
    private val pitchMethodChannelName = "com.ofthewolf.aubiotuner/pitch_method"
    private val eventChannelName = "com.ofthewolf.aubiotuner/pitch_event"
    private var streamHandler: FlutterStreamHandler? = null

    private var sampleRate = 0
    private var bufferSize = 0
    private var amountRead = 0
    private var buffer: FloatArray? = null
    private var intermediaryBuffer: ShortArray? = null

    /* These variables are used to store pointers to the C objects so JNI can keep track of them */
    var ptr: Long = 0
    var input: Long = 0
    var pitch: Long = 0

    var isRecording = false
    private var audioRecord: AudioRecord? = null
    var audioThread: Thread? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setUpEventChannel()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pitchMethodChannelName).setMethodCallHandler {
                call, result ->
            if (call.method == "startRecording") {
                configureRecordParams()
                val isStarted = startRecordingIfAllowed()
                result.success(isStarted)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun configureRecordParams() {
        sampleRate = 44100
        bufferSize = 2048
        buffer = FloatArray(bufferSize)
        intermediaryBuffer = ShortArray(bufferSize)
    }

    //
    fun startRecordingIfAllowed(): Boolean {
        if (!isRecording) {
            isRecording = true
            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.RECORD_AUDIO
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return false
            }
            startRecording()
            return true
        }
        return false
    }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    private fun startRecording() {
        val sampleRate = 44100f
        val bufferSize = 4096
        val lowPassFreq = 880f
        val highPassFreq = 55f

        val dispatcher = AudioDispatcherFactory.fromDefaultMicrophone(sampleRate.toInt(), bufferSize, 0)

        val pdh = PitchDetectionHandler { result, e ->
            val pitchInHz = result.pitch
            streamHandler?.sendEventStream(pitchInHz.toDouble())
        }
        val p: AudioProcessor = PitchProcessor(PitchEstimationAlgorithm.FFT_YIN, sampleRate, bufferSize, pdh)
        dispatcher.addAudioProcessor(p)
        Thread(dispatcher, "Audio Dispatcher").start()
//
//        audioRecord = AudioRecord(
//            MediaRecorder.AudioSource.DEFAULT, sampleRate, AudioFormat.CHANNEL_IN_DEFAULT,
//            AudioFormat.ENCODING_PCM_16BIT, bufferSize
//        )
//        audioRecord?.startRecording()
//        audioThread = Thread({ findNote() }, "Tuner Thread")
//        audioThread!!.start()
//        initPitch(44100, 1024)
    }

    private fun findNote() {
        while (isRecording) {
            amountRead = audioRecord?.read(intermediaryBuffer!!, 0, bufferSize)!!
            buffer = shortArrayToFloatArray(intermediaryBuffer!!)
            val frequency: Float = getPitch(buffer!!)
            streamHandler?.sendEventStream(frequency)
        }
    }

    private fun shortArrayToFloatArray(array: ShortArray): FloatArray {
        val fArray = FloatArray(array.size)
        for (i in array.indices) {
            fArray[i] = array[i].toFloat()
        }
        return fArray
    }

    private fun setUpEventChannel() {
        val eventChannel = EventChannel(flutterEngine?.dartExecutor?.binaryMessenger, eventChannelName)
        this.streamHandler = this.streamHandler
            ?: FlutterStreamHandler()
        eventChannel.setStreamHandler(this.streamHandler)
    }

    companion object
    {
        init {
            System.loadLibrary("aubiopitch")
        }
    }

    private external fun getPitch(input: FloatArray): Float
    private external fun initPitch(sampleRate: Int, bufferSize: Int)
}

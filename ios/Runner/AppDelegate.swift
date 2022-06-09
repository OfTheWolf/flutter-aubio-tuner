import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var streamHandler: SwiftStreamHandler?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller = window?.rootViewController as! FlutterViewController
        let eventChannel = FlutterEventChannel(name: "com.ofthewolf.aubiotuner/pitch_event",
                                               binaryMessenger: controller.binaryMessenger)
        if (self.streamHandler == nil) {
            self.streamHandler = SwiftStreamHandler()
        }
        
        eventChannel.setStreamHandler((self.streamHandler!))
        
        let pitchChannel = FlutterMethodChannel(name: "com.ofthewolf.aubiotuner/pitch_method",
                                                  binaryMessenger: controller.binaryMessenger)
        pitchChannel.setMethodCallHandler({[weak self]
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "startRecording" else {
                result(FlutterMethodNotImplemented)
                return
              }
            guard let sSelf = self else {
                result(FlutterError(code: "Unknown",
                                    message: "Unknown failure",
                                    details: nil))
                return
            }
            
            let isStarted = sSelf.startRecording()
            result(isStarted)
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()
    
    func startRecording() -> Bool{
        do {
            try session.setCategory(AVAudioSession.Category.record)
            
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            let bufferSize: uint_t = 4096
            let sampleRate: uint_t = UInt32(format.sampleRate)

            init_aubio(bufferSize, sampleRate)

            inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: format) { (buffer, time) in
                let channelData = buffer.floatChannelData![0]
                let freq = process_aubio(channelData, Int32(bufferSize))
                self.streamHandler?.eventSink?(freq)
            }
            try audioEngine.start()
            return true
        } catch _ {
            return false
        }
    }
    
}

class SwiftStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
}


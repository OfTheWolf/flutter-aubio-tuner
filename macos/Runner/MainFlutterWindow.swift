import Cocoa
import FlutterMacOS
import AVFoundation

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController.init()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        setupChannels()
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        super.awakeFromNib()
    }
    
    private var streamHandler: SwiftStreamHandler?
    
    func setupChannels() {
        let controller = contentViewController as! FlutterViewController
        let eventChannel = FlutterEventChannel(name: "com.ofthewolf.aubiotuner/pitch_event",
                                               binaryMessenger: controller.engine.binaryMessenger)
        if (self.streamHandler == nil) {
            self.streamHandler = SwiftStreamHandler()
        }
        
        eventChannel.setStreamHandler((self.streamHandler!))
        
        let pitchChannel = FlutterMethodChannel(name: "com.ofthewolf.aubiotuner/pitch_method",
                                                binaryMessenger: controller.engine.binaryMessenger)
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
        
    }
    
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    
    func startRecording() -> Bool{
        do {
            
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

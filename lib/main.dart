import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const eventChannel = EventChannel('com.ofthewolf.aubiotuner/pitch_event');
  static const pitchMethodChannel =
      MethodChannel('com.ofthewolf.aubiotuner/pitch_method');

  double _pitch = 0;
  double _angle = 0;
  double _lastCent = 0;

  @override
  void initState() {
    super.initState();
    startRecordingIfReady();
  }

  void startRecordingIfReady() async {
    final bool micPermissionGranted = await _checkPermissions();
    if (micPermissionGranted) {
      await startRecording();
      _configureEventChannel();
    } else {}
  }

  Future<void> startRecording() async {
    final bool status = await pitchMethodChannel.invokeMethod('startRecording');
    if (status) {
      //recording started
    } else {
      //handle failure
    }
  }

  Future<bool> _checkPermissions() async {
    //permission_handler lib only supports android and ios
    if (Platform.isAndroid || Platform.isIOS){
      final status = await Permission.microphone.status;
      switch (status) {
        case PermissionStatus.granted:
          return true;
        case PermissionStatus.denied:
          return await Permission.microphone.request() ==
              PermissionStatus.granted;
        case PermissionStatus.permanentlyDenied:
          openAppSettings();
          return false;
        default:
          return false;
      }
    }else{
      // handle persmissions on other platforms
      return true;
    }

  }

  void _configureEventChannel() {
    Stream<double> eventStream =
        eventChannel.receiveBroadcastStream().cast<double>();
    eventStream.listen((event) {
      double cents = event.toCent();
      if (event > 0) {
        setState(() {
          _pitch = (event * 100).round() / 100.0;
          _angle = event.angle();
          _lastCent = cents;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Welcome to Flutter',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Welcome to Flutter'),
          ),
          body: Column(
            children: [
              Padding(padding: const EdgeInsets.all(20.0)),
              Wrap(children: [SfRadialGauge(axes: <RadialAxis>[
                RadialAxis(
                    startAngle: 180 - 45,
                    endAngle: 45,
                    minimum: -50,
                    maximum: 50,
                    ranges: <GaugeRange>[
                      GaugeRange(
                          startValue: -10,
                          endValue: 10,
                          color: Colors.greenAccent,
                          startWidth: 10,
                          endWidth: 10),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        enableAnimation: true,
                          animationType: AnimationType.ease,
                          value: _angle,
                          gradient: LinearGradient(colors: <Color>[
                            Color(0xFFFF6B78),
                            Color(0xFFFF6B78),
                            Color(0xFFE20A22),
                            Color(0xFFE20A22)
                          ], stops: <double>[
                            0,
                            0.5,
                            0.5,
                            1
                          ]),
                          needleColor: Color(0xFFF67280),
                          knobStyle: KnobStyle(
                              knobRadius: 0.09,
                              sizeUnit: GaugeSizeUnit.factor,
                              color: Colors.black)),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                          widget: Container(
                              child: Text('${_pitch}',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold))),
                          angle: 90,
                          positionFactor: 0.5)
                    ])
              ])],
            )],
          ),
        ));
  }
}

extension Pitch on double {
  double logBase(num x, num base) => log(x) / log(base);

  double toCent() {
    double cent = 1200.0 * logBase(this / 440.0, 2);
    return cent % 100;
  }

  double angle() {
    double cent = toCent();
    print(cent);
    if (cent > 50){
      return cent - 100;
    }
    return cent;
  }
}
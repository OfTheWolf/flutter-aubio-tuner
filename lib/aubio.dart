import 'dart:ffi'; // For FFI
import 'dart:io'; // For Platform.isX
import 'package:ffi/ffi.dart';

final DynamicLibrary aubioLib = Platform.isAndroid
    ? DynamicLibrary.open('libaubiopitch.so')
    : DynamicLibrary.process();

///  init aubio with params
final void Function(int bufferSize, int sampleRate) aubioInit = aubioLib
    .lookup<NativeFunction<Void Function(Uint32, Uint32)>>('init_aubio')
    .asFunction();

///  clear memory for aubio
final void Function() aubioDelete = aubioLib
    .lookup<NativeFunction<Void Function()>>('delete_aubio')
    .asFunction();

/// aubio process function with callback
typedef ProcessCallbackType = Void Function(Double);

typedef ProcessInType = Void Function(Pointer<Double>, Int32 nFrames,
    Pointer<NativeFunction<ProcessCallbackType>>);

typedef ProcessOutType = void Function(Pointer<Double> buffer,
    int nFrames, Pointer<NativeFunction<ProcessCallbackType>>);

final ProcessOutType nativeAubioProcess =
    aubioLib.lookup<NativeFunction<ProcessInType>>('process').asFunction();

void callback(double freq) {
  if (freq != 0){
    print('freq callback=$freq');
  }
}

void aubioProcess(List<double> buffer, int nFrames) {
  Pointer<Double> pointer = calloc.allocate(sizeOf<Double>()*buffer.length);
  for(int i = 0; i < buffer.length; i++){
    pointer.elementAt(i).value = buffer[i];
  }

  nativeAubioProcess(
      pointer, nFrames, Pointer.fromFunction<ProcessCallbackType>(callback));

  calloc.free(pointer);

}

  // final myStrings = ['asdf', 'fsda'];
  // final List<Pointer<Utf8>> myPointers = myStrings.map(Utf8.toUtf8);
  // final Pointer<Pointer<Utf8>> pointerPointer =
  //     allocate(count: myStrings.length);
  // for (int i = 0; i < myStrings.length; i++) {
  //   pointerPointer[i] = myPointers[i];
  // }
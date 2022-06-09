
import 'dart:js' as js;

import 'dart:js';


int nativeAdd(int x, int y){
  return context.callMethod('native_add', [x, y]);
}


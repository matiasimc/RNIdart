import 'package:client_package_sample/client_package_sample.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Foo {
  int foo(@declared("asd") String a, Bar b) {
    return 1+1;
  }
}

class Bar {
  String bar(@declared("asd") String a) {
    return a.substring(0).toLowerCase();
  }
}
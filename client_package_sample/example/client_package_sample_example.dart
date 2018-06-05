import 'package:client_package_sample/client_package_sample.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Foo {
  @declared("public") void foo(@declared("asd") String a, Bar b) {
    b.bar(a);
  }
}

class Bar {
  void bar(@declared("asd") String a) {
    a.substring(0).toLowerCase();
  }
}
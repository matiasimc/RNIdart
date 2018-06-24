import '../sec.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Bar {
  int a = 5,b = 4,c = 3;

  Bar nuevo() => new Bar();
}

class Foo {
  void foo(Bar x) {
    x.b;
    x.nuevo().b.toString();
  }
}
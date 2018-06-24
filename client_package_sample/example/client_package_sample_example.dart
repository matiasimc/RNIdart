import '../sec.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Foo {

  @declared("StringToStringAndSubstring") String foo(@declared("StringToString") String s) {
    s.toString();
    return s;
  }
}

class Bar {
  @declared("StringToString") String foo(Baz b) {
    return b.baz();
  }
}

class Baz {
  @declared("Top") String baz() {
    return "hola";
  }
}
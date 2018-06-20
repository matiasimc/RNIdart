import '../sec.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Baz {
  void baz(Foo b) {
    b.foo(b);
    b.bar(b);
  }
}

class Foo {
  void bar(Foo b) {
    b.chao("Mati");
  }

  void foo(Foo b) {
    b.hola("Mati");
  }

  void hola(String name) {
    name.toString();
  }

  void chao(String name) {
    name.toLowerCase();
  }
}

class FooBar {
  String bar(@declared("Bot") String s) {
    return s;
  }
}
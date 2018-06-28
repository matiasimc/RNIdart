import 'package:TRNIdart/src/public_interface.dart';

class LoginScreen {
  String a = new Bar().getBaz();
  bool login(String guess, @declared("Top") String password) {
    //return password.compareTo(guess) == 0;
    return guess.compareTo(password) == 0;
  }
}

class Foo {
  String foo(Bar b) {
    if (b.cond()) {
      @declared("StringToString") String s = "asd";
      s.toString();
    }
    return b.getBaz();
  }

  @declared("Bot") Bar test(Bar b) {
    b.getBaz();
    return b;
  }
}

class Bar {

  @declared("StringToString") String getBaz() {
    return "asd";
  }

  @declared("Bot") bool cond() {
    return true;
  }
}

class Baz {
  String foo(String s) {
    return s.toLowerCase().substring(0).length.toString();
  }

  String rec1() {
    return rec2();
  }

  String rec2() {
    return rec1();
  }
}
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
      @declared("Bot") String s = "asd";
      s.toString();
    }
    return b.getBaz();
  }

  String test(Bar b) {
    String ret;
    ret = b.getBaz();
    return ret;
  }
}

class Bar {

  @declared("StringToString") String getBaz() {
    return "asd";
  }

  @declared("Top") bool cond() {
    return true;
  }
}

class Baz {
  String foo(String s) {
    return s.toLowerCase().substring(0).length.toString();
  }
}
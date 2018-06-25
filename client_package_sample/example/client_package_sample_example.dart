import 'package:TRNIdart/src/public_interface.dart';

class LoginScreen {
  bool login(String guess, @declared("Top") String password) {
    //return password.compareTo(guess) == 0;
    return guess.compareTo(password) == 0;
  }
}

class Foo {
  String foo(Bar b) {
    return b.getBaz();
  }
}

class Bar {
  @declared("Top") String getBaz() {
    return "asd";
  }
}

class Baz {
  String foo(String s) {
    return s.toLowerCase().substring(0).toString();
  }
}
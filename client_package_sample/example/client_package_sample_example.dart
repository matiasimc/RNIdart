import 'package:TRNIdart/src/public_interface.dart';

class LoginScreen {
  bool foo(@S("Top") String p1) {
    p1.toLowerCase();
  }

  bool bar(@S("Top") String p2) {
    p2.toUpperCase();
    foo(p2);
  }
}

class Login {
  /*
  The method login should return "Top".
   */
  int login(String guess, @S("Top") String password) {
    return password.compareTo(guess);
  }
}
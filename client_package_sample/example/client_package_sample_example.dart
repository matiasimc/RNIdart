import 'package:TRNIdart/src/public_interface.dart';


class LoginScreen {
  int login1(@S("Top") String password) {
    return password.length.abs();
  }

  int login2(String guess, @S("StringCompareTo") String password) {
    return password.compareTo(guess);
  }

  void login3(String guess, @S("Top") String password) {
    check1(password.toLowerCase());
  }

  void login4(String guess, @S("Top") String password) {
    check2(password.toLowerCase());
  }

  String check1(String password) {
    return password.substring(0);
  }

  String check2(@S("Bot") String password) {
    return password.substring(0);
  }
}
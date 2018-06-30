import 'package:TRNIdart/src/public_interface.dart';


class LoginScreen {
  String check(int b) {
    return b.toRadixString(1);
  }

  String login(String guess, @S("Top") String password) {
    check(password.compareTo(guess));
    return password.compareTo(guess).toString();
  }
}
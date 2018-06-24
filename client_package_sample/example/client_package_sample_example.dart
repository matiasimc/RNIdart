import 'package:TRNIdart/src/public_interface.dart';

class LoginScreen {
  bool login(String guess, @declared("Top") String password) {
    //return password.compareTo(guess) == 0;
    return guess.compareTo(password) == 0;
  }
}
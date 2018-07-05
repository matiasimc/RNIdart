import 'package:TRNIdart/src/public_interface.dart';
class Person{
  @S("Top") String get name => "asd";
  int get age => 4;
}

class Body{
  String foo(/*T*/ Person p){
    return p.name;
  }
}
class Body2{
  String foo(@S("Bot") Person p){
    return p.name.toLowerCase();
  }
}

class LoginScreen {
  int login(String password, String guess){
    return password.compareTo(guess);
  }
  //el de arriba deberia inferir bot en el retorno, bot para guess
  //y para password. {comparaTo:}

  int login2(String guess, @S("StringCompareTo") String password) {
    return password.compareTo(guess);
  }
  //el tipo de retorno deberia ser bot.

  int login21(@S("Top")String password, String guess){
    return password.compareTo(guess);
  }


  int login1(@S("Top") String password) {
    return password.length.abs();
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

class Foo {
  int foo(@S("StringHashAbs") String s) {
    return s.hashCode.ceil();
  }
}
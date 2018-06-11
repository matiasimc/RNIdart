import 'package:TRNIdart/src/public_interface.dart';

class Foo {
  @declared(Bot) int foo(@declared(Top) String a, Bar b) {
    return 1+1;
  }
}

class Bar {
  String bar(@declared(Top) String a) {
    return a.substring(0).toLowerCase();
  }
}
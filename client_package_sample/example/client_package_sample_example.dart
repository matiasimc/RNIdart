import '../sec.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Foo {
  @declared("Bot") String foo(@declared("Top") String a, Bar b) {
    return b.bar("asd");
  }
}

class Bar {
  String bar(String a) {
    return a.toString().substring(0);
  }
}
import '../sec.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Foo {
  @declared("Bot") int foo(@declared("Top") String a, Bar b) {
    return 1+1;
  }
}

class Bar {
  @declared("Bot") String bar(@declared("StringToString") String a) {
    return a.toString();
  }
}
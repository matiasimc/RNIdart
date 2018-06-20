import '../sec.dart';
import 'package:TRNIdart/src/public_interface.dart';

class Foo {
  String bar(@declared("StringToStringAndSubstring") String s) {
    return s.substring(0);
  }
}
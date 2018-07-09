import 'package:TRNIdart/src/public_interface.dart';

class Foo {
  int foo(@S("StringHashAbs") String s) {
    @S("Bot") int ret = s.hashCode.ceil();
    return ret;
  }
}
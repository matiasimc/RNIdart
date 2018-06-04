import 'package:client_package_sample/client_package_sample.dart';
import 'package:TRNIdart/src/public_interface.dart';

@declared("public") void foo(@declared("asd") String a, String b) {
  int c = d*4;
  String x = "asd";
}

@declared("public") main() {
  @declared("private") Awesome awesome = new Awesome();
  print('awesomememe: ${awesome.isAwesome}');
}

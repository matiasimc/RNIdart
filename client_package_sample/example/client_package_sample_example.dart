import 'package:client_package_sample/client_package_sample.dart';
import 'package:TRNIdart/src/public_interface.dart';

@interface("public") void foo(@interface("asd") String a, String b) {
  String x = "asd";
}

@interface("public") main() {
  @interface("private") Awesome awesome = new Awesome();
  print('awesomememe: ${awesome.isAwesome}');
}

import 'package:analyzer/analyzer.dart';

class Usage {
    List<MethodInvocation> methodCalls;
    List<PrefixedIdentifier> fieldCalls;

    Usage() {
      this.methodCalls = new List<MethodInvocation>();
      this.fieldCalls = new List<PrefixedIdentifier>();
    }
}
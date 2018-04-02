import 'package:analyzer/analyzer.dart';
import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';
/*
This class manages the local variable definitions.
 */

class LocalEnvironment {
  Map<VariableDeclaration, Usage> variables;
  Map<AstNode, Usage> chainedCalls;

  LocalEnvironment() {
    this.variables = new Map<VariableDeclaration, Usage>();
    this.chainedCalls = new Map<MethodInvocation, Usage>();
  }
}
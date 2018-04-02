import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';
import 'package:analyzer/analyzer.dart';

class FunctionElement {
  Map<SimpleFormalParameter, Usage> parameterUsage;
  FunctionDeclaration node;

  FunctionElement(FunctionDeclaration node) {
    this.parameterUsage = new Map<SimpleFormalParameter, Usage>();
    this.node = node;
  }
}
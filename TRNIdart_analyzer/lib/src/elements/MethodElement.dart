import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/analyzer.dart';

class MethodElement {
  Map<SimpleFormalParameter, Usage> parameterUsage;
  MethodDeclaration node;

  MethodElement(MethodDeclaration node) {
    this.parameterUsage = new Map<SimpleFormalParameter, Usage>();
    this.node = node;
  }
}
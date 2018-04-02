import 'package:analyzer/analyzer.dart';
import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';

class ClassElement {
  Map<String, MethodElement> methods;
  Map<String, FieldElement> fields;
  ClassDeclaration node;

  ClassElement(ClassDeclaration node) {
    this.methods = new Map<String, MethodElement>();
    this.fields = new Map<String, FieldElement>();
    this.node = node;
  }
}
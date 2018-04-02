import 'package:analyzer/analyzer.dart';
import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';

class ClassDeclarationVisitor extends RecursiveAstVisitor {
  GlobalEnvironment env;
  ClassElement classElement;

  ClassDeclarationVisitor(GlobalEnvironment env, ClassElement classElement) {
    this.env = env;
    this.classElement = classElement;
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    // TODO call method declaration visitor, similar to FunctionDeclarationVisitor
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    // TODO call field declaration visitor
  }
}
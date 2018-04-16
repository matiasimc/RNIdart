import 'package:analyzer/analyzer.dart';
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class ClassDeclarationVisitor extends RecursiveAstVisitor {
  GlobalEnvironment env;
  ClassElement classElement;

  ClassDeclarationVisitor(GlobalEnvironment env, ClassElement classElement) {
    this.env = env;
    this.classElement = classElement;
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (!this.classElement.methods.containsKey(node.element.name)) {
      MethodElement m = new MethodElement(node);
      this.classElement.methods[node.element.name] = m;
      node.visitChildren(new MethodDeclarationVisitor(this.env, m));
    }
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    if (!this.classElement.fields.containsKey(node.element.name)) {
      FieldElement f = new FieldElement(node);
      this.classElement.fields[node.element.name] = f;
      // TODO call field declaration visitor
    }
  }
}
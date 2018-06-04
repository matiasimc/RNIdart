/*
In this file there should be a class that visits the AST looking for classes to
generate object types with type variables and declared types.
Returns a Store.
 */

import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class AnnotationLookupCUVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("AnnotationLookupCUVisitor");
  Store store;

  AnnotationLookupVisitor() {
    this.store = new Store();
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    log.shout("Visiting class ${node.name}");
    store.addObjectTypeVariable(node.name.toString());
    node.members.accept(new AnnotationLookupClassVisitor(this.store));
  }
}

class AnnotationLookupClassVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("AnnotationLookupClassVisitor");
  Store store;

  AnnotationLookupClassVisitor(this.store);

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    // TODO generar TVar para todos los parametros sin @declared
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    // TODO
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    // TODO almacenar constructor con nombre especial?
  }
}
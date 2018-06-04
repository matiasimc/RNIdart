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
    ObjectType t = store.addObjectTypeVariable(node.name.toString());
    node.members.accept(new AnnotationLookupClassVisitor(t, this.store));
  }
}

class AnnotationLookupClassVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("AnnotationLookupClassVisitor");
  ObjectType t;
  Store store;

  AnnotationLookupClassVisitor(this.t, this.store);

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    // TODO generar TVar para todos los parametros y retorno sin @declared
    List<IType> left = node.parameters.parameters.map((p) {
      // if p is declared, object type of declared type
      // else, new type variable
      return store.getTypeVariable();
    }).toList();
    // for the right side, the same as the left
    IType right = store.getTypeVariable();
    t.addMember(node.name.toString(), new ArrowType(left, right));
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
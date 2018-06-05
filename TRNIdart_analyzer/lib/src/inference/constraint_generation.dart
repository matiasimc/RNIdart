import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class CompilationUnitVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("CompilationUnitVisitor");
  Store store;
  ConstraintSet cs;
  IType chainedCallParentType;

  CompilationUnitVisitor() {
    this.store = new Store();
    this.cs = new ConstraintSet();
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    log.shout("Visiting class ${node.name}");
    node.members.accept(new ClassMemberVisitor(this.store, this.cs));
  }

}


class ClassMemberVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("ClassMemberVisitor");
  Store store;
  ConstraintSet cs;

  ClassMemberVisitor(this.store, this.cs);

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    log.shout("Visiting method ${node.name}");
    if (!store.hasElement(node.element)) {
      List<IType> left = node.parameters.parameters.map((p) {
        Annotation a = AnnotationHelper.getDeclaredForParameter(p);
        if (a == null) {
          IType tvar = store.getTypeVariable();
          this.store.addElement(p.element, tvar);
          return tvar;
        }
        else {
          IType t = new DeclaredType(a.arguments.arguments.first.toString());
          this.store.addElement(p.element, t);
          return t;
        }
      }).toList();
      Annotation a = AnnotationHelper.getDeclared(node);
      IType right = a != null ?
        new DeclaredType(a.arguments.arguments.first.toString()) :
        store.getTypeVariable();
      store.addElement(node.element, new ArrowType(left, right));
    }
    node.body.accept(new MethodBodyVisitor(this.store, this.cs));
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    log.shout("Visiting field(s) ${node.fields.variables.join(',')}");
    if (store.hasElement(node.element)) return;
    Annotation a = AnnotationHelper.getDeclared(node);
    IType t = a != null ?
      new DeclaredType(a.arguments.arguments.first.toString()) :
      store.getTypeVariable();
    store.addElement(node.element, t);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    log.shout("Visiting constructor");
    if (!store.hasElement(node.element)) {
      List<IType> left = node.parameters.parameters.map((p) {
        Annotation a = AnnotationHelper.getDeclaredForParameter(p);
        if (a == null)
          return store.getTypeVariable();
        else
          return new DeclaredType(a.arguments.arguments.first.toString());
      }).toList();
      Annotation a = AnnotationHelper.getDeclared(node);
      IType right = a != null ?
      new DeclaredType(a.arguments.arguments.first.toString()) :
      store.getTypeVariable();
      store.addElement(node.element, new ArrowType(left, right));
    }
  }
}

class MethodBodyVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("MethodBodyVisitor");
  Store store;
  ConstraintSet cs;
  IType chainedCallParentType;

  MethodBodyVisitor(this.store, this.cs);

  @override
  visitMethodInvocation(MethodInvocation node) {
    log.shout("Found method invocation ${node}");
    if (!store.hasElement(node.staticInvokeType.element)) {
      node.accept(new ClassMemberVisitor(this.store, this.cs));
    }
    AstNode target = node.target;
    IType targetType;
    if (target is SimpleIdentifier) {
      targetType = this.store.getTypeOrVariable(target.bestElement);
    }
    if (targetType == null) targetType = this.store.getTypeVariable();
    ArrowType methodSignature;
    if (node.staticInvokeType.element.library.isDartCore) {
      methodSignature = new ArrowType(node.argumentList.arguments.map((a) => new Top()).toList(), new Bot());
    }
    else {
      methodSignature = this.store.getTypeOrVariable(
          node.staticInvokeType.element);
    }
    IType callType = new ObjectType(
        {node.methodName.toString(): methodSignature});
    //TVar(i) <: {m: x -> y}
    this.cs.addConstraint(new SubtypingConstraint(targetType, callType));
    if (node.parent is MethodInvocation || node.parent is PrefixedIdentifier) {
      // y <: chainedCallParentType
      this.cs.addConstraint(new SubtypingConstraint(methodSignature.rightSide, chainedCallParentType));
    }
    chainedCallParentType = targetType;
    return super.visitMethodInvocation(node);
  }
}
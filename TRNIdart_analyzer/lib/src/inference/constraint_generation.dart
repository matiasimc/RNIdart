import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/src/generated/source.dart';


class CompilationUnitVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("CompilationUnitVisitor");
  Store store;
  ConstraintSet cs;
  Map<String, IType> declaredStore;
  Source source;
  ErrorCollector collector;

  CompilationUnitVisitor(this.store, this.cs, this.declaredStore, this.collector, this.source);

  @override
  visitCompilationUnit(CompilationUnit node) {
    node.declarations.accept(this);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    if (node.isAbstract) {
      DeclaredParser parser = new DeclaredParser();
      node.accept(parser);
      if (this.declaredStore.containsKey(node.element.name)) {
        this.cs.addConstraint(new DeclaredConstraint(this.declaredStore[node.element.name], parser.getType(), location));
      }
      else {
        this.declaredStore[node.element.name] = parser.getType();
      }
    }
    log.shout("Visiting class ${node.name}");
    node.members.accept(new ClassMemberVisitor(this.store, this.cs, this.declaredStore, this.collector, this.source));
  }

}

class ImportVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("ImportVisitor");
  bool hasTarget;

  ImportVisitor() {
    this.hasTarget = false;
  }

  @override
  visitImportDirective(ImportDirective node) {
    String imp = node.uri.toString();
    if (imp.contains("sec.dart")) {
      this.hasTarget = true;
    }
    else return super.visitImportDirective(node);
  }
}

class ClassMemberVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("ClassMemberVisitor");
  Store store;
  ConstraintSet cs;
  Map<String, IType> declaredStore;
  Source source;
  ErrorCollector collector;

  ClassMemberVisitor(this.store, this.cs, this.declaredStore, this.collector, this.source);

  IType processReturnType(ClassMember node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    Annotation a = AnnotationHelper.getDeclared(node);
    IType right;
    if (a != null) {
      String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
      if (this.declaredStore.containsKey(facet)) {
        IType t = this.declaredStore[facet];
        IType tvar = this.store.getTypeVariable(new Bot());
        this.cs.addConstraint(new DeclaredConstraint(tvar, t, location));
        right = tvar;
      }
      else {
          collector.errors.add(new UndefinedFacetError(node.element, facet));
          IType tvar1 = this.store.getTypeVariable(new Bot());
          this.declaredStore[facet] = tvar1;
          IType tvar2 = this.store.getTypeVariable(new Bot());
          this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1, location));
          right = tvar2;

      }
    }
    else right = store.getTypeVariable(new Bot());
    return right;
  }

  List<IType> processParametersType(MethodDeclaration node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    List<IType> left = node.element.parameters.map((p) {
      Annotation a = AnnotationHelper.getDeclaredForParameter(p.computeNode());
      if (a == null) {
        IType tvar = store.getTypeOrVariable(p, new Top());
        return tvar;
      }
      else {
        String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
        if (this.declaredStore.containsKey(facet)) {
          IType t = this.declaredStore[facet];
          IType tvar = this.store.getTypeOrVariable(p, new Top());
          this.cs.addConstraint(new DeclaredConstraint(tvar, t, location));
          return tvar;
        }
        else {
          collector.errors.add(new UndefinedFacetError(p, facet));
          IType tvar1 = this.store.getTypeVariable(new Top());
          this.declaredStore[facet] = tvar1;
          IType tvar2 = this.store.getTypeOrVariable(p, new Top());
          this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1, location));
          return tvar2;
        }
      }
    }).toList();
    return left;
  }

  List<IType> processParametersTypeForConstructor(ConstructorDeclaration node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    List<IType> left = node.element.parameters.map((p) {
      Annotation a = AnnotationHelper.getDeclaredForParameter(p.computeNode());
      if (a == null) {
        IType tvar = store.getTypeOrVariable(p, new Top());
        return tvar;
      }
      else {
        String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
        if (this.declaredStore.containsKey(facet)) {
          IType t = this.declaredStore[facet];
          IType tvar = this.store.getTypeOrVariable(p, new Top());
          this.cs.addConstraint(new DeclaredConstraint(tvar, t, location));
          return tvar;
        }
        else {
          IType tvar1 = this.store.getTypeVariable(new Top());
          this.declaredStore[facet] = tvar1;
          IType tvar2 = this.store.getTypeOrVariable(p, new Top());
          this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1, location));
          return tvar2;
        }
      }
    }).toList();
    return left;
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Visiting method ${node.name}");
    /*
    First, we look for declared annotations in parameters. If exists, then we
    generate a DeclaredConstraint for the type variable and the declared type. Else,
    we just add the type variable.
     */
    processParametersType(node);
    /*
    The same goes for the return type. Then, we create the ArrowType.
     */
    IType right = processReturnType(node);
    /*
    If the store doesn't has the method element, we add it. Else, we create the
    constraint associating the type in the store with the newly created arrow
    type.
     */
    if (!store.hasElement(node.element)) store.addElement(node.element, new Bot(), right);
    else {
      cs.addConstraint(new SubtypingConstraint(store.getType(node.element), right, location));
      cs.addConstraint(new SubtypingConstraint(right, store.getType(node.element), location));
    }
    /*
    Finally, we process the method body.
     */
    node.body.accept(new MethodBodyVisitor(this.store, this.cs, right, this.source));
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    log.shout("Visiting field(s) ${node.fields.variables.join(',')}");
    if (store.hasElement(node.element)) return;
    IType right = processReturnType(node);
    store.addElement(node.element, new Bot(), right);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Visiting constructor");
    if (!store.hasElement(node.element)) {
      processParametersTypeForConstructor(node);
      IType right = processReturnType(node);
      cs.addConstraint(new SubtypingConstraint(store.getTypeOrVariable(node.element, new Bot()), right, location));
    }
  }
}

class MethodBodyVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("MethodBodyVisitor");
  Store store;
  ConstraintSet cs;
  IType returnType;
  IType chainedCallParentType;
  Source source;

  MethodBodyVisitor(this.store, this.cs, this.returnType, this.source);

  IType processExpression(Expression e) {
    Element element;
    if (e is SimpleIdentifier) {
      element = e.bestElement;
      return this.store.getTypeOrVariable(element, new Bot());
    }
    else if (e is InstanceCreationExpression) {
      element = e.staticElement;
      return this.store.getTypeOrVariable(element, new Bot());
    }
    else if (e is MethodInvocation) {
      element = e.staticInvokeType.element;
      return this.store.getTypeOrVariable(element, new Bot());
    }
    else if (e is PrefixedIdentifier) {
      element = e.bestElement;
      return this.store.getTypeOrVariable(element, new Bot());
    }
    else {
      return new Bot();
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Found method invocation ${node}");
    /*
    First, we identify the target node. If it's a variable, we get it from the
    store. Else, we generate a type variable.
     */
    AstNode target = node.target;
    IType targetType;
    if (target is SimpleIdentifier) {
      targetType = this.store.getTypeOrVariable(target.bestElement, new Bot());
    }
    if (targetType == null) targetType = this.store.getTypeVariable(new Bot());
    /*
    Now we check the method signature, generating the constraint between
    arguments and parameters.
     */
    IType methodReturn;
    IType variableReturn;
    List<IType> variableParameters;
    if (node.staticInvokeType.element.library != null && node.staticInvokeType.element.library.isDartCore && !(node.parent is MethodInvocation || node.parent is PrefixedIdentifier)) {
      variableReturn = new Bot();
    }
    else {
      variableReturn = this.store.getTypeVariable(new Bot());
    }
    methodReturn = this.store.getTypeOrVariable(node.staticInvokeType.element, new Bot());

    this.cs.addConstraint(new SubtypingConstraint(methodReturn, variableReturn, location));

    variableParameters = node.argumentList.arguments.map((a) {
      IType parType;
      if (node.staticInvokeType.element.library != null && node.staticInvokeType.element.library.isDartCore) {
        parType = new Top();
      }
      else {
        parType = this.store.getTypeOrVariable(a.bestParameterElement, new Top());
      }
      IType argType = processExpression(a);
      this.cs.addConstraint(new SubtypingConstraint(argType, parType, location));
      return parType;
    }).toList();

    ArrowType methodSignature = new ArrowType(variableParameters, variableReturn);

    /*
    Now we generate the object type and the constraint for the target, and
    check if the target is part of a chained method call. If it is, we add the
    corresponding constraint.
     */
    IType callType = new ObjectType(
        {node.methodName.toString(): methodSignature});
    // TVar(i) <: {m: x -> y}
    this.cs.addConstraint(new SubtypingConstraint(targetType, callType, location));
    if (node.parent is MethodInvocation || node.parent is PrefixedIdentifier) {
      // y <: chainedCallParentType
      this.cs.addConstraint(new SubtypingConstraint(methodSignature.rightSide, chainedCallParentType, location));
    }
    /*
    Finally, we update the variable that store the necessary type for chained
    method calls.
     */
    chainedCallParentType = targetType;
    return super.visitMethodInvocation(node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    this.cs.addConstraint(new SubtypingConstraint(processExpression(node.expression), this.returnType, location));
    return super.visitReturnStatement(node);
  }
}
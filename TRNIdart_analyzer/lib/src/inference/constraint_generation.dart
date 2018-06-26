import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CompilationUnitVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("CompilationUnitVisitor");
  Store store;
  ConstraintSet cs;
  Map<String, IType> declaredStore;

  CompilationUnitVisitor(this.store, this.cs, this.declaredStore);

  @override
  visitCompilationUnit(CompilationUnit node) {
/*    bool hasTarget = false;
    node.directives.forEach((d) {
      if (d is ImportDirective) {
        String imp = d.uri.toString();
        if (imp.contains("sec.dart")) {
          hasTarget = true;
        }
      }
    });
    if (!hasTarget) {
      File f = new File(node.element.librarySource.toString());
      String oldContents = f.readAsStringSync();
      String relativePath = path.relative(this.secFile, from: f.path.replaceAll("/"+node.element.librarySource.shortName, ""));
      String importDirective = "import '${relativePath}';\n";
      String newContents = importDirective+oldContents;
      f.writeAsStringSync(newContents);
    }*/

    node.declarations.accept(this);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (node.isAbstract) {
      DeclaredParser parser = new DeclaredParser();
      node.accept(parser);
      if (this.declaredStore.containsKey(node.element.name)) {
        this.cs.addConstraint(new DeclaredConstraint(this.declaredStore[node.element.name], parser.getType()));
      }
      else {
        this.declaredStore[node.element.name] = parser.getType();
      }
    }
    log.shout("Visiting class ${node.name}");
    node.members.accept(new ClassMemberVisitor(this.store, this.cs, this.declaredStore));
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

  ClassMemberVisitor(this.store, this.cs, this.declaredStore);

  IType processReturnType(ClassMember node) {
    Annotation a = AnnotationHelper.getDeclared(node);
    IType right;
    if (a != null) {
      String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
      if (this.declaredStore.containsKey(facet)) {
        IType t = this.declaredStore[facet];
        IType tvar = this.store.getTypeVariable(new Bot());
        this.cs.addConstraint(new DeclaredConstraint(tvar, t));
        right = tvar;
      }
      else {
        IType tvar1 = this.store.getTypeVariable(new Bot());
        this.declaredStore[facet] = tvar1;
        IType tvar2 = this.store.getTypeVariable(new Bot());
        this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1));
        right = tvar2;
      }
    }
    else right = store.getTypeVariable(new Bot());
    return right;
  }

  List<IType> processParametersType(MethodDeclaration node) {
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
          this.cs.addConstraint(new DeclaredConstraint(tvar, t));
          return tvar;
        }
        else {
          IType tvar1 = this.store.getTypeVariable(new Top());
          this.declaredStore[facet] = tvar1;
          IType tvar2 = this.store.getTypeOrVariable(p, new Top());
          this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1));
          return tvar2;
        }
      }
    }).toList();
    return left;
  }

  List<IType> processParametersTypeForConstructor(ConstructorDeclaration node) {
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
          this.cs.addConstraint(new DeclaredConstraint(tvar, t));
          return tvar;
        }
        else {
          IType tvar1 = this.store.getTypeVariable(new Top());
          this.declaredStore[facet] = tvar1;
          IType tvar2 = this.store.getTypeOrVariable(p, new Top());
          this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1));
          return tvar2;
        }
      }
    }).toList();
    return left;
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    log.shout("Visiting method ${node.name}");
    /*
    First, we look for declared annotations in parameters. If exists, then we
    generate a DeclaredConstraint for the type variable and the declared type. Else,
    we just add the type variable.
     */
    List<IType> left = processParametersType(node);
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
    else cs.addConstraint(new SubtypingConstraint(store.getType(node.element), right));
    /*
    Finally, we process the method body.
     */
    node.body.accept(new MethodBodyVisitor(this.store, this.cs, right));
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    log.shout("Visiting field(s) ${node.fields.variables.join(',')}");
    IType right = processReturnType(node);
    for (VariableDeclaration v in node.fields.variables) {
      log.shout("Element of this shit ${v.name.bestElement} ${v.name.bestElement.runtimeType}");
      if (!store.hasElement(v.name.bestElement)) store.addElement(v.name.bestElement, new Bot(), right);
      else cs.addConstraint(new SubtypingConstraint(store.getType(v.name.bestElement), right));
      v.initializer.accept(new MethodBodyVisitor(store, cs, right));
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    log.shout("Visiting constructor");
    if (!store.hasElement(node.element)) {
      List<IType> left = processParametersTypeForConstructor(node);
      IType right = processReturnType(node);
      cs.addConstraint(new SubtypingConstraint(store.getTypeOrVariable(node.element, new Bot()), right));
    }
  }
}

class MethodBodyVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("MethodBodyVisitor");
  Store store;
  ConstraintSet cs;
  IType returnType;
  IType chainedCallParentType;

  MethodBodyVisitor(this.store, this.cs, this.returnType);

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
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    log.shout("Found field invocation on variable ${node}");
    Element propertyAccessor = node.identifier.bestElement;
    if (propertyAccessor is PropertyAccessorElement) {
      log.shout("element of this node ${node.identifier.bestElement} is ${propertyAccessor.variable} ${propertyAccessor.variable.runtimeType}");
      /*
      The target node of prefixedIndentifier is always a variable.
     */
      IType target = this.store.getTypeOrVariable(node.prefix.bestElement, new Bot());

      IType fieldReturn = this.store.getTypeOrVariable(propertyAccessor.variable, new Bot());
      IType variableReturn = this.store.getTypeVariable(new Bot());
      this.cs.addConstraint(new SubtypingConstraint(fieldReturn, variableReturn));

      FieldType fieldSignature = new FieldType(variableReturn);

      IType callType = new ObjectType({node.bestElement.name: fieldSignature});

      this.cs.addConstraint(new SubtypingConstraint(target, callType));

      /*
    no need to check for chainedCalls because this field call only occurs on variables.
     */

      chainedCallParentType = target;
    }



    return super.visitPrefixedIdentifier(node);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    log.shout("Found field invocation on object ${node}");

    Element propertyAccessor = node.propertyName.bestElement;
    if (propertyAccessor is PropertyAccessorElement) {
      log.shout("element of this node ${node.propertyName.bestElement} is ${propertyAccessor.variable} ${propertyAccessor.variable.runtimeType}");

      /*
      The target node of prefixedIndentifier is always a variable.
     */
      IType target = processExpression(node.target);

      IType fieldReturn = this.store.getTypeOrVariable(propertyAccessor.variable, new Bot());
      IType variableReturn = this.store.getTypeVariable(new Bot());
      this.cs.addConstraint(new SubtypingConstraint(fieldReturn, variableReturn));

      FieldType fieldSignature = new FieldType(variableReturn);

      IType callType = new ObjectType({node.propertyName.name: fieldSignature});

      this.cs.addConstraint(new SubtypingConstraint(target, callType));
      if (node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) {
        // y <: chainedCallParentType
        this.cs.addConstraint(new SubtypingConstraint(fieldSignature.rightSide, chainedCallParentType));
      }
      /*
    Finally, we update the variable that store the necessary type for chained
    method calls.
     */
      chainedCallParentType = target;
    }

    return super.visitPropertyAccess(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
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
    methodReturn = this.store.getTypeOrVariable(
        node.staticInvokeType.element, new Bot());
    variableReturn = this.store.getTypeVariable(new Bot());
    this.cs.addConstraint(new SubtypingConstraint(methodReturn, variableReturn));

    variableParameters = node.argumentList.arguments.map((a) {
      IType parType = this.store.getTypeOrVariable(a.bestParameterElement, new Top());
      IType argType = processExpression(a);
      this.cs.addConstraint(new SubtypingConstraint(argType, parType));
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
    this.cs.addConstraint(new SubtypingConstraint(targetType, callType));
    if (node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) {
      // y <: chainedCallParentType
      this.cs.addConstraint(new SubtypingConstraint(methodSignature.rightSide, chainedCallParentType));
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
    // this constraint should be expresion <: returnType
    this.cs.addConstraint(new SubtypingConstraint(processExpression(node.expression), this.returnType));
    // this.cs.addConstraint(new SubtypingConstraint(this.returnType, processExpression(node.expression)));
    return super.visitReturnStatement(node);
  }
}
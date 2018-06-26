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
        /*
        this try/catch is because the element of "node.element" may not exist
        when typing the facet, due to this case: @declString foo...
         */
        try {
          collector.errors.add(new UndefinedFacetError(node.element, facet));
          IType tvar1 = this.store.getTypeVariable(new Bot());
          this.declaredStore[facet] = tvar1;
          IType tvar2 = this.store.getTypeVariable(new Bot());
          this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1, location));
          right = tvar2;
        }
        catch(e){}

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
          try {
            collector.errors.add(new UndefinedFacetError(p, facet));
            IType tvar1 = this.store.getTypeVariable(new Top());
            this.declaredStore[facet] = tvar1;
            IType tvar2 = this.store.getTypeOrVariable(p, new Top());
            this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1, location));
            return tvar2;
          }
          catch(e) {}
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
    node.body.accept(new BlockVisitor(this.store, this.cs, right, this.source, declaredStore, collector, new Bot()));
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    log.shout("Visiting field(s) ${node.fields.variables.join(',')}");
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    IType right = processReturnType(node);
    for (VariableDeclaration v in node.fields.variables) {
      if (!store.hasElement(v.name.bestElement)) store.addElement(v.name.bestElement, new Bot(), right);
      else {
        cs.addConstraint(new SubtypingConstraint(store.getType(v.name.bestElement), right, location));
        cs.addConstraint(new SubtypingConstraint(right, store.getType(v.name.bestElement), location));
      }
      // TODO generate constraint for the initialization
      if (v.initializer != null) {
        BlockVisitor visitor = new BlockVisitor(store, cs, right, source, declaredStore, collector, new Bot());
        cs.addConstraint(new SubtypingConstraint(visitor.processExpression(v.initializer), right, location));
        v.initializer.accept(visitor);
      }
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Visiting constructor");
    processParametersTypeForConstructor(node);
    IType right = processReturnType(node);
    if (!store.hasElement(node.element)) {
      store.addElement(node.element, new Bot(), right);
    }
    else {
      cs.addConstraint(new SubtypingConstraint(store.getType(node.element), right, location));
      cs.addConstraint(new SubtypingConstraint(right, store.getType(node.element), location));
    }
    node.body.accept(new BlockVisitor(this.store, this.cs, right, this.source, this.declaredStore, this.collector, new Bot()));
  }
}

class BlockVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("BlockVisitor");
  Store store;
  ConstraintSet cs;
  IType returnType;
  IType chainedCallParentType;
  Source source;
  Map<String, IType> declaredStore;
  ErrorCollector collector;
  IType pc;

  BlockVisitor(this.store, this.cs, this.returnType, this.source, this.declaredStore, this.collector, this.pc);

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
      Element el = e.identifier.bestElement;
      if (el is PropertyAccessorElement) return this.store.getTypeOrVariable(el.variable, new Bot());
      else return new Bot();
    }
    else if (e is PropertyAccess) {
      Element el = e.propertyName.bestElement;
      if (el is PropertyAccessorElement) return this.store.getTypeOrVariable(el.variable, new Bot());
      else return new Bot();
    }
    else {
      return new Bot();
    }
  }

  IType processReturnType(VariableDeclarationList node) {
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
        /*
        this try/catch is because the element of "node.element" may not exist
        when typing the facet, due to this case: @declString foo...
         */
        try {
          collector.errors.add(new UndefinedFacetError(node.variables.first.element.enclosingElement, facet));
          IType tvar1 = this.store.getTypeVariable(new Bot());
          this.declaredStore[facet] = tvar1;
          IType tvar2 = this.store.getTypeVariable(new Bot());
          this.cs.addConstraint(new DeclaredConstraint(tvar2, tvar1, location));
          right = tvar2;
        }
        catch(e){}

      }
    }
    else right = store.getTypeVariable(new Bot());
    return right;
  }

  @override
  visitIfStatement(IfStatement node) {
    node.condition.accept(this);
    IType cond = processExpression(node.condition);
    ErrorLocation location = new ErrorLocation(source, node.condition.length, node.condition.offset, node.condition);
    IType newPC = store.getTypeVariable(new Bot());
    this.cs.addConstraint(new SubtypingConstraint(cond, newPC, location));
    this.cs.addConstraint(new SubtypingConstraint(pc, newPC, location));
    BlockVisitor visitor = new BlockVisitor(store, cs, returnType, source, declaredStore, collector, newPC);
    node.thenStatement.accept(visitor);
    if (node.elseStatement != null) node.elseStatement.accept(visitor);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    log.shout("Found assignment expresion ${node}");
    ErrorLocation location = new ErrorLocation(source, node.length, node.offset, node);
    IType left = processExpression(node.leftHandSide);
    IType right = processExpression(node.rightHandSide);
    this.cs.addConstraint(new SubtypingConstraint(right, left, location));
    //this.cs.addConstraint(new SubtypingConstraint(right, pc, location));
    return super.visitAssignmentExpression(node);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    log.shout("Found variable declarations ${node}");
    IType left = processReturnType(node);
    ErrorLocation location = new ErrorLocation(source, node.length, node.offset, node);
    for (VariableDeclaration v in node.variables) {
      IType right = this.store.getTypeOrVariable(v.element, new Bot());
      this.cs.addConstraint(new SubtypingConstraint(right, left, location));
      if (v.initializer != null) {
        IType init = processExpression(v.initializer);
        this.cs.addConstraint(new SubtypingConstraint(init, right, location));
        //this.cs.addConstraint(new SubtypingConstraint(init, pc, location));
      }
    }
    return super.visitVariableDeclarationList(node);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    log.shout("Found field invocation on variable ${node}");
    Element propertyAccessor = node.identifier.bestElement;
    if (propertyAccessor is PropertyAccessorElement && !propertyAccessor.variable.isSynthetic) {
      ErrorLocation location = new ErrorLocation(this.source,node.length, node.offset, node);
      /*
      The target node of prefixedIndentifier is always a variable.
     */
      IType target = this.store.getTypeOrVariable(node.prefix.bestElement, new Bot());

      IType fieldReturn = this.store.getTypeOrVariable(propertyAccessor.variable, new Bot());
      IType variableReturn;
      if (propertyAccessor.variable.library != null && propertyAccessor.variable.library.isDartCore && !(node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess)) {
        variableReturn = new Bot();
      }
      else variableReturn = this.store.getTypeVariable(new Bot());
      if (fieldReturn != null)  this.cs.addConstraint(new SubtypingConstraint(fieldReturn, variableReturn, location));

      FieldType fieldSignature = new FieldType(variableReturn);

      IType callType = new ObjectType({node.bestElement.name: fieldSignature});

      if (target != null) this.cs.addConstraint(new SubtypingConstraint(target, callType, location));

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
      ErrorLocation location = new ErrorLocation(this.source,node.length, node.offset, node);
      /*
      The target node of prefixedIndentifier is always a variable.
     */
      IType target = processExpression(node.target);

      IType fieldReturn = this.store.getTypeOrVariable(propertyAccessor.variable, new Bot());
      IType variableReturn;
      if (propertyAccessor.variable.library != null && propertyAccessor.variable.library.isDartCore && !(node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess)) {
        variableReturn = new Bot();
      }
      else variableReturn = this.store.getTypeVariable(new Bot());
      if (fieldReturn != null) this.cs.addConstraint(new SubtypingConstraint(fieldReturn, variableReturn, location));

      FieldType fieldSignature = new FieldType(variableReturn);

      IType callType = new ObjectType({node.propertyName.name: fieldSignature});

      if (target != null) this.cs.addConstraint(new SubtypingConstraint(target, callType, location));
      if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedCallParentType != null) {
        // y <: chainedCallParentType
        ErrorLocation parentLocation = new ErrorLocation(source, node.parent.length, node.parent.offset, node.parent);
        this.cs.addConstraint(new SubtypingConstraint(fieldSignature.rightSide, chainedCallParentType, parentLocation));
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
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Found method invocation ${node}");
    /*
    First, we identify the target node. If it's a variable, we get it from the
    store. Else, we generate a type variable.
     */
    AstNode target = node.target;
    IType targetType;
    if (target is SimpleIdentifier) {
      Element bestElement = target.bestElement;
      if (bestElement is PropertyAccessorElement) {
        targetType = this.store.getTypeOrVariable(bestElement.variable, new Bot());
      }
      else {
        targetType = this.store.getTypeOrVariable(bestElement, new Bot());
      }
    }
    if (targetType == null) targetType = this.store.getTypeVariable(new Bot());
    /*
    Now we check the method signature, generating the constraint between
    arguments and parameters.
     */
    IType methodReturn;
    IType variableReturn;
    List<IType> variableParameters;
    if (node.staticInvokeType.element.library != null && node.staticInvokeType.element.library.isDartCore && !(node.parent is MethodInvocation || node.parent is PrefixedIdentifier|| node.parent is PropertyAccess)) {
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
    if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedCallParentType != null) {
      // y <: chainedCallParentType
      ErrorLocation parentLocation = new ErrorLocation(source, node.parent.length, node.parent.offset, node.parent);
      this.cs.addConstraint(new SubtypingConstraint(methodSignature.rightSide, chainedCallParentType, parentLocation));
    }
    /*
    Finally, we update the variable that store the necessary type for chained
    method calls.
     */
    chainedCallParentType = targetType;
    return super.visitMethodInvocation(node);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Found instance creation ${node}");
    /*
    We check the constructor signature, generating the constraint between
    arguments and parameters.
     */
    if (node.staticElement != null) {
      IType methodReturn;
      IType variableReturn;
      if (node.staticElement.library != null && node.staticElement.library.isDartCore) {
        variableReturn = new Bot();
      }
      else {
        variableReturn = this.store.getTypeVariable(new Bot());
      }
      methodReturn = this.store.getTypeOrVariable(node.staticElement, new Bot());

      this.cs.addConstraint(new SubtypingConstraint(methodReturn, variableReturn, location));

      node.argumentList.arguments.forEach((a) {
        IType parType;
        if (node.staticElement.library != null && node.staticElement.library.isDartCore) {
          parType = new Top();
        }
        else {
          parType = this.store.getTypeOrVariable(a.bestParameterElement, new Top());
        }
        IType argType = processExpression(a);
        this.cs.addConstraint(new SubtypingConstraint(argType, parType, location));
      });

      if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedCallParentType != null) {
        // y <: chainedCallParentType
        ErrorLocation parentLocation = new ErrorLocation(source, node.parent.length, node.parent.offset, node.parent);
        this.cs.addConstraint(new SubtypingConstraint(variableReturn, chainedCallParentType, parentLocation));
      }
    }

    return super.visitInstanceCreationExpression(node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    this.cs.addConstraint(new SubtypingConstraint(processExpression(node.expression), this.returnType, location));
    return super.visitReturnStatement(node);
  }
}
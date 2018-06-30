import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:TRNIdart_analyzer/analyzer.dart';


class CompilationUnitVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("CompilationUnitVisitor");
  Store store;
  ConstraintSet cs;
  Map<String, IType> declaredStore;
  Source source;
  ErrorCollector collector;
  bool testMode;

  CompilationUnitVisitor(this.store, this.cs, this.declaredStore, this.collector, this.source, this.testMode);

  @override
  visitCompilationUnit(CompilationUnit node) {
    node.declarations.accept(this);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (node.isAbstract && (source.uri.path == TRNIAnalyzer.secDartFile || testMode)) {
      log.shout("Visiting abstract class ${node.name}");
      DeclaredParser parser = new DeclaredParser();
      node.accept(parser);
      IType newT = parser.getType();
      if (declaredStore.containsKey(node.element.name)) {
        IType oldT = declaredStore[node.element.name];
        this.store.types.forEach((i, t) {
          if (t == oldT) this.store.types[i] = newT;
        });
        this.cs.constraints.forEach((c) {
          ConstraintSolver solver = new ConstraintSolver(store, cs, collector);
          c.left = solver.substitute(c.left, oldT, newT);
          c.right = solver.substitute(c.right, oldT, newT);
        });
      }
      this.declaredStore[node.element.name] = newT;
    }
    else {
      log.shout("Visiting class ${node.name}");
      node.members.accept(new ClassMemberVisitor(this.store, this.cs, this.declaredStore, this.collector, this.source));
    }
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
    Annotation a = AnnotationHelper.getDeclared(node);
    IType right;
    if (a != null) {
      String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
      if (this.declaredStore.containsKey(facet)) {
        IType old = this.store.getType(node.element);
        this.store.addElement(node.element, new Bot(), declaredType: declaredStore[facet]);
        if (old != null) {
          this.cs.constraints.forEach((c) {
            ConstraintSolver solver = new ConstraintSolver(store, cs, collector);
            c.left = solver.substitute(c.left, old, declaredStore[facet]);
            c.right = solver.substitute(c.right, old, declaredStore[facet]);
          });
        }
        right = declaredStore[facet];
      }
      else {
        /*
        this try/catch is because the element of "node.element" may not exist
        when typing the facet, due to this case: @declString foo...
         */
        try {
          collector.errors.add(new UndefinedFacetError(node.element, facet));
          right = this.store.getTypeVariable(new Bot());
          this.declaredStore[facet] = right;
        }
        catch(e){}

      }
    }
    else {
      right = store.getTypeVariable(new Bot());
    }
    return right;
  }

  List<IType> processParametersType(MethodDeclaration node) {
    List<IType> left = node.element.parameters.map((p) {
      Annotation a = AnnotationHelper.getDeclaredForParameter(p.computeNode());
      if (a == null) {
        IType tvar = store.getTypeOrVariable(p, defaultType: new Top());
        return tvar;
      }
      else {
        String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
        if (this.declaredStore.containsKey(facet)) {
          IType old = this.store.getType(p);
          this.store.addElement(p, new Bot(), declaredType: declaredStore[facet]);
          if (old != null) {
            this.cs.constraints.forEach((c) {
              ConstraintSolver solver = new ConstraintSolver(store, cs, collector);
              c.left = solver.substitute(c.left, old, declaredStore[facet]);
              c.right = solver.substitute(c.right, old, declaredStore[facet]);
            });
          }
          return declaredStore[facet];
        }
        else {
          try {
            collector.errors.add(new UndefinedFacetError(p, facet));
            IType tvar1 = this.store.getTypeVariable(new Top());
            this.declaredStore[facet] = tvar1;
            return tvar1;
          }
          catch(e) {}
        }
      }
    }).toList();
    return left;
  }

  List<IType> processParametersTypeForConstructor(ConstructorDeclaration node) {
    List<IType> left = node.element.parameters.map((p) {
      Annotation a = AnnotationHelper.getDeclaredForParameter(p.computeNode());
      if (a == null) {
        IType tvar = store.getTypeOrVariable(p, defaultType: new Top());
        return tvar;
      }
      else {
        String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
        if (this.declaredStore.containsKey(facet)) {
          IType old = this.store.getType(p);
          this.store.addElement(p, new Bot(), declaredType: declaredStore[facet]);
          if (old != null) {
            this.cs.constraints.forEach((c) {
              ConstraintSolver solver = new ConstraintSolver(store, cs, collector);
              c.left = solver.substitute(c.left, old, declaredStore[facet]);
              c.right = solver.substitute(c.right, old, declaredStore[facet]);
            });
          }
          return declaredStore[facet];
        }
        else {
          try {
            collector.errors.add(new UndefinedFacetError(p, facet));
            IType tvar1 = this.store.getTypeVariable(new Top());
            this.declaredStore[facet] = tvar1;
            return tvar1;
          }
          catch(e) {}
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
    if (!store.hasElement(node.element)) store.addElement(node.element, new Bot(), declaredType: right);
    else {
      cs.addConstraint(new SubtypingConstraint(right, store.getType(node.element), [location]));
      //cs.addConstraint(new SubtypingConstraint(store.getType(node.element), right, [location]));
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
      if (!store.hasElement(v.name.bestElement)) store.addElement(v.name.bestElement, new Bot(), declaredType: right);
      else {
        cs.addConstraint(new SubtypingConstraint(store.getType(v.name.bestElement), right, [location]));
        cs.addConstraint(new SubtypingConstraint(right, store.getType(v.name.bestElement), [location]));
      }
      // TODO generate constraint for the initialization
      if (v.initializer != null) {
        BlockVisitor visitor = new BlockVisitor(store, cs, right, source, declaredStore, collector, new Bot());
        cs.addConstraint(new SubtypingConstraint(visitor.processExpression(v.initializer), right, [location]));
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
      store.addElement(node.element, new Bot(), declaredType: right);
    }
    else {
      cs.addConstraint(new SubtypingConstraint(store.getType(node.element), right, [location]));
      cs.addConstraint(new SubtypingConstraint(right, store.getType(node.element), [location]));
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
  IType chainedReturnType;
  Source source;
  Map<String, IType> declaredStore;
  ErrorCollector collector;
  IType pc;
  IType lastExpression;
  bool lastExpressionIsArgument;

  BlockVisitor(this.store, this.cs, this.returnType, this.source, this.declaredStore, this.collector, this.pc, {this.lastExpression, this.lastExpressionIsArgument});

  IType processExpression(Expression e, {isArgument: false}) {
    IType ret = store.getTypeVariable(new Bot());
    lastExpression = ret;
    lastExpressionIsArgument = isArgument;
    return ret;
  }

  IType processReturnType(VariableDeclarationList node) {
    Annotation a = AnnotationHelper.getDeclared(node);
    IType right;
    if (a != null) {
      String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
      if (this.declaredStore.containsKey(facet)) {
        for (VariableDeclaration v in node.variables) {
          IType old = this.store.getType(v.element);
          this.store.addElement(v.element, new Bot(), declaredType: declaredStore[facet]);
          if (old != null) {
            this.cs.constraints.forEach((c) {
              ConstraintSolver solver = new ConstraintSolver(store, cs, collector);
              c.left = solver.substitute(c.left, old, declaredStore[facet]);
              c.right = solver.substitute(c.right, old, declaredStore[facet]);
            });
          }
        }
        right = declaredStore[facet];
      }
      else {
        /*
        this try/catch is because the element of "node.element" may not exist
        when typing the facet, due to this case: @declString foo...
         */
        try {
          for (VariableDeclaration v in node.variables) {
            collector.errors.add(new UndefinedFacetError(v.element, facet));
          }
          right = this.store.getTypeVariable(new Bot());
          this.declaredStore[facet] = right;
        }
        catch(e){}

      }
    }
    else right = store.getTypeVariable(new Bot());
    return right;
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    ErrorLocation location = new ErrorLocation(source, node.length, node.offset, node);
    if (lastExpression != null) {
      IType varType = store.getTypeOrVariable(node.bestElement, defaultType: new Bot());
      cs.addConstraint(new SubtypingConstraint(lastExpression, varType, [location]));
      cs.addConstraint(new SubtypingConstraint(varType, lastExpression, [location]));
      lastExpression = null;
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  visitThisExpression(ThisExpression node) {
    visitAnyLiteral(node);
    return super.visitThisExpression(node);
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
    visitAnyLiteral(node);
    return super.visitSimpleStringLiteral(node);
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) {
    visitAnyLiteral(node);
    return super.visitIntegerLiteral(node);
  }

  @override
  visitBooleanLiteral(BooleanLiteral node) {
    visitAnyLiteral(node);
    return super.visitBooleanLiteral(node);
  }

  @override
  visitNullLiteral(NullLiteral node) {
    visitAnyLiteral(node);
    return super.visitNullLiteral(node);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    visitAnyLiteral(node);
    return super.visitDoubleLiteral(node);
  }

  void visitAnyLiteral(AstNode node) {
    ErrorLocation location = new ErrorLocation(source, node.length, node.offset, node);
    if (lastExpression != null) {
      IType t = store.getTypeVariable(new Bot(), dartCoreType: new Bot());
      if (lastExpressionIsArgument) t = store.getTypeVariable(new Top(), dartCoreType: new Top());
      cs.addConstraint(new SubtypingConstraint(lastExpression, t, [location]));
      cs.addConstraint(new SubtypingConstraint(t, lastExpression, [location]));
      lastExpression = null;
    }
  }

  @override
  visitIfStatement(IfStatement node) {
    node.condition.accept(this);
    IType cond = processExpression(node.condition);
    ErrorLocation location = new ErrorLocation(source, node.condition.length, node.condition.offset, node.condition);
    IType newPC = store.getTypeVariable(new Bot());
    this.cs.addConstraint(new SubtypingConstraint(cond, newPC, [location]));
    this.cs.addConstraint(new SubtypingConstraint(pc, newPC, [location]));
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
    this.cs.addConstraint(new SubtypingConstraint(right, left, [location]));
    this.cs.addConstraint(new SubtypingConstraint(pc, left, [location]));
    return super.visitAssignmentExpression(node);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    log.shout("Found variable declarations ${node}");
    IType left = processReturnType(node);
    ErrorLocation location = new ErrorLocation(source, node.length, node.offset, node);
    for (VariableDeclaration v in node.variables) {
      IType right = this.store.getTypeOrVariable(v.element, defaultType: new Bot());
      this.cs.addConstraint(new SubtypingConstraint(right, left, [location]));
      if (v.initializer != null) {
        IType init = processExpression(v.initializer);
        this.cs.addConstraint(new SubtypingConstraint(init, right, [location]));
        this.cs.addConstraint(new SubtypingConstraint(pc, right, [location]));
      }
    }
    return super.visitVariableDeclarationList(node);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    log.shout("Found field invocation on variable ${node}");
    IType localLastExpression = lastExpression;

    Element propertyAccessor = node.identifier.bestElement;
    if (propertyAccessor is PropertyAccessorElement && !propertyAccessor.variable.isSynthetic) {
      ErrorLocation location = new ErrorLocation(this.source,node.length, node.offset, node);
      /*
      The target node of prefixedIndentifier is always a variable.
     */
      IType target = this.store.getTypeOrVariable(node.prefix.bestElement, defaultType: new Bot());

      IType dartCoreType;
      if (propertyAccessor.variable.library != null && propertyAccessor.variable.library.isDartCore && !(node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess)) {
        dartCoreType = new Bot();
      }

      IType fieldReturn = this.store.getTypeOrVariable(propertyAccessor.variable, defaultType: new Bot(), dartCoreType: dartCoreType);
      FieldType fieldSignature = new FieldType(fieldReturn);

      IType callType = new ObjectType({node.bestElement.name: fieldSignature});

      if (target != null) {
        this.cs.addConstraint(new SubtypingConstraint(target, callType, [location]));
      }

      if (localLastExpression != null) {
        IType expType = fieldReturn;
        if (target != null && target.isConcrete() && !target.subtypeOf(callType)) {
          expType = new Top();
          if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedReturnType != null) {
            cs.addConstraint(new SubtypingConstraint(expType, chainedReturnType, [location]));
          }
          else chainedReturnType = null;
        }
        if (chainedReturnType == null) {
          cs.addConstraint(new SubtypingConstraint(expType, localLastExpression, [location]));
          cs.addConstraint(new SubtypingConstraint(localLastExpression, expType, [location]));
        }
        lastExpression = null;
      }

      /*
    no need to check for chainedCalls because this field call only occurs on variables.
     */

      chainedCallParentType = target;
      chainedCallParentType = target;
      if (!(node.prefix is SimpleIdentifier) && node.prefix != null) {
        if (chainedReturnType == null) chainedReturnType = fieldReturn;
        node.prefix.accept(this);
      }
    }



    return super.visitPrefixedIdentifier(node);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    log.shout("Found field invocation on object ${node}");
    IType localLastExpression = lastExpression;

    Element propertyAccessor = node.propertyName.bestElement;
    if (propertyAccessor is PropertyAccessorElement) {
      ErrorLocation location = new ErrorLocation(this.source,node.length, node.offset, node);

      IType target = processExpression(node.target);

      IType dartCoreType;
      if (propertyAccessor.variable.library != null && propertyAccessor.variable.library.isDartCore && !(node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess)) {
        dartCoreType = new Bot();
      }
      IType fieldReturn = this.store.getTypeOrVariable(propertyAccessor.variable, defaultType: new Bot(), dartCoreType: dartCoreType);

      FieldType fieldSignature = new FieldType(fieldReturn);

      IType callType = new ObjectType({node.propertyName.name: fieldSignature.rightSide});

      if (target != null) {
        this.cs.addConstraint(new SubtypingConstraint(target, callType, [location]));
      }
      if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedCallParentType != null) {
        // y <: chainedCallParentType
        ErrorLocation parentLocation = new ErrorLocation(source, node.parent.length, node.parent.offset, node.parent);
        this.cs.addConstraint(new SubtypingConstraint(fieldSignature.rightSide, chainedCallParentType, [parentLocation]));
      }

      if (localLastExpression != null) {
        IType expType = fieldReturn;
        if (target != null && target.isConcrete() && !target.subtypeOf(callType)) {
          expType = new Top();
          if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedReturnType != null) {
            cs.addConstraint(new SubtypingConstraint(expType, chainedReturnType, [location]));
          }
          else chainedReturnType = null;
        }
        if (chainedReturnType == null) {
          cs.addConstraint(new SubtypingConstraint(expType, localLastExpression, [location]));
          cs.addConstraint(new SubtypingConstraint(localLastExpression, expType, [location]));
        }
        lastExpression = null;
      }

      /*
    Finally, we update the variable that store the necessary type for chained
    method calls.
     */
      chainedCallParentType = target;
      if (!(node.target is SimpleIdentifier) && node.target != null) {
        if (chainedReturnType == null) chainedReturnType = fieldReturn;
        node.target.accept(this);
      }
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Found method invocation ${node}");
    IType localLastExpression = lastExpression;
    bool argAnalyzed = false;
    /*
    First, we identify the target node. If it's a variable, we get it from the
    store. Else, we generate a type variable. Note that a target that has a
    concrete type in the store has to be declared.
     */
    AstNode target = node.target;
    IType targetType;
    if (target is SimpleIdentifier) {
      Element bestElement = target.bestElement;
      if (bestElement is PropertyAccessorElement) {
        targetType = this.store.getTypeOrVariable(bestElement.variable, defaultType: new Bot());
      }
      else {
        targetType = this.store.getTypeOrVariable(bestElement, defaultType: new Bot());
      }
    }
    if (targetType == null) targetType = this.store.getTypeVariable(new Bot());
    /*
    Now we check the method signature, generating the constraint between
    arguments and parameters.
     */
    IType methodReturn;
    IType dartCoreType;
    List<IType> variableParameters;
    if (node.staticInvokeType.element.library != null && node.staticInvokeType.element.library.isDartCore && !(node.parent is MethodInvocation || node.parent is PrefixedIdentifier|| node.parent is PropertyAccess)) {
      dartCoreType = new Bot();
    }
    methodReturn = this.store.getTypeOrVariable(node.staticInvokeType.element, defaultType: new Bot(), dartCoreType: dartCoreType);

    if (node.argumentList.arguments.isNotEmpty) argAnalyzed = true;

    variableParameters = node.argumentList.arguments.map((a) {
      IType parType;
      if (node.staticInvokeType.element.library != null && node.staticInvokeType.element.library.isDartCore) {
        parType = this.store.getTypeVariable(new Top(), dartCoreType: new Top());
      }
      else {
        parType = this.store.getTypeOrVariable(a.bestParameterElement, defaultType: new Top());
      }
      IType argType = processExpression(a, isArgument: true);
      this.cs.addConstraint(new SubtypingConstraint(argType, parType, [location]));
      a.accept(new BlockVisitor(store, cs, returnType, source, declaredStore, collector, pc, lastExpression: lastExpression, lastExpressionIsArgument: lastExpressionIsArgument));
      return parType;
    }).toList();

    ArrowType methodSignature = new ArrowType(variableParameters, methodReturn);

    /*
    Now we generate the object type and the constraint for the target, and
    check if the target is part of a chained method call. If it is, we add the
    corresponding constraint.
     */
    IType callType = new ObjectType(
        {node.methodName.toString(): methodSignature});
    // TVar(i) <: {m: x -> y}
    this.cs.addConstraint(new SubtypingConstraint(targetType, callType, [location], true));


    if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedCallParentType != null) {
      // y <: chainedCallParentType
      ErrorLocation parentLocation = new ErrorLocation(source, node.parent.length, node.parent.offset, node.parent);
      this.cs.addConstraint(new SubtypingConstraint(methodSignature.rightSide, chainedCallParentType, [parentLocation]));
    }

    if (localLastExpression != null) {
      IType expType = methodReturn;
      if (targetType != null && targetType.isConcrete() && !targetType.subtypeOf(callType)) {
        expType = new Top();
        if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedReturnType != null) {
          cs.addConstraint(new SubtypingConstraint(expType, chainedReturnType, [location]));
        }
        else chainedReturnType = null;
      }
      if (chainedReturnType == null) {
        cs.addConstraint(new SubtypingConstraint(expType, localLastExpression, [location]));
        cs.addConstraint(new SubtypingConstraint(localLastExpression, expType, [location]));
      }
      if (!argAnalyzed && targetType.isConcrete()) lastExpression = null;
    }
    /*
    Finally, we update the variable that store the necessary type for chained
    method calls.
     */
    chainedCallParentType = targetType;
    if (!(target is SimpleIdentifier) && target != null) {
      if (chainedReturnType == null) chainedReturnType = methodReturn;
      target.accept(this);
    }
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    log.shout("Found instance creation ${node}");
    IType localLastExpression = lastExpression;
    bool argAnalyzed = false;
    /*
    We check the constructor signature, generating the constraint between
    arguments and parameters.
     */
    if (node.staticElement != null) {
      IType methodReturn;
      IType dartCoreType;
      if (node.staticElement.library != null && node.staticElement.library.isDartCore) {
        dartCoreType = new Bot();
      }
      methodReturn = this.store.getTypeOrVariable(node.staticElement, defaultType: new Bot(), dartCoreType: dartCoreType);
      argAnalyzed = node.argumentList.arguments.isNotEmpty;

      node.argumentList.arguments.forEach((a) {
        IType parType;
        if (node.staticElement.library != null && node.staticElement.library.isDartCore) {
          parType = this.store.getTypeVariable(new Top(), dartCoreType: new Top());
        }
        else {
          parType = this.store.getTypeOrVariable(a.bestParameterElement, defaultType: new Top());
        }
        IType argType = processExpression(a, isArgument: true);
        this.cs.addConstraint(new SubtypingConstraint(argType, parType, [location]));
      });

      if ((node.parent is MethodInvocation || node.parent is PrefixedIdentifier || node.parent is PropertyAccess) && chainedCallParentType != null) {
        // y <: chainedCallParentType
        ErrorLocation parentLocation = new ErrorLocation(source, node.parent.length, node.parent.offset, node.parent);
        this.cs.addConstraint(new SubtypingConstraint(methodReturn, chainedCallParentType, [parentLocation]));
      }

      if (localLastExpression != null) {
        cs.addConstraint(new SubtypingConstraint(methodReturn, localLastExpression, [location]));
        cs.addConstraint(new SubtypingConstraint(localLastExpression, methodReturn, [location]));
        if (!argAnalyzed) lastExpression = null;
      }
    }

    return super.visitInstanceCreationExpression(node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    ErrorLocation location = new ErrorLocation(this.source, node.length, node.offset, node);
    this.cs.addConstraint(new SubtypingConstraint(processExpression(node.expression), this.returnType, [location]));
    return super.visitReturnStatement(node);
  }
}
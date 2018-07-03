import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class ConstraintSolver {
  final Logger log = new Logger("ConstraintSolver");
  ConstraintSet cs;
  Store store;
  ErrorCollector collector;
  Map<TVar, Set<Constraint>> groupedConstraints;
  Set<ErrorLocation> locationsWithErrors = new Set();

  ConstraintSolver(this.store, this.cs, this.collector);

  bool hasNull(IType t) {
    if (t == null) return true;
    else {
      if (t is ArrowType) return t.leftSide.any((t1) => hasNull(t1)) || hasNull(t.rightSide);
      if (t is ObjectType) return t.members.values.any((t1) => hasNull(t1));
    }
    return false;
  }

  void solve() {
    /*
    If there is no type variable to solve, return
     */
    if (this.store.varIndex < 1) return;

    /*
    If there is a constraint with a "null" type inside, we remove it
     */
    this.cs.constraints.removeWhere((c) => hasNull(c.left) || hasNull(c.right));

    log.shout("Step 0");
    /*
    Then, we reduce the case when we have x <: y and y <: x. To to this, we look
    the store:

    - if x and y are in the store, then we replace y for x in the store and in every
      constraint, and delete both constraints x <: y and y <: x.

    - if x is in the store and not y, then we replace y for x in every constraint,
      and delete both constraints. We do the opposite if y is in the store and not x.

    - if x nor y are in the store, then we replace x for y in every constraint,
      and delete both constraints.
    */
    Set<Constraint> removableConstraints = this.cs.constraints.where((c) {
      return c.left is TVar && c.right is TVar && (this.cs.constraints.any((c2) => c.left == c2.right && c.right == c2.left));
    }).toSet();

    this.cs.constraints.removeWhere((c) => removableConstraints.contains(c));

    for (Constraint c in removableConstraints) {
      if (this.store.types.values.contains(c.left) && this.store.types.values.contains(c.right)) {
        this.store.types.keys.forEach((int k) {
          if (this.store.types[k] == c.right) this.store.types[k] = c.left;
        });
        this.cs.constraints.forEach((c1) {
          c1.left = substitute(c1.left, c.right, c.left);
          c1.right = substitute(c1.right, c.right, c.left);

        });
      }

      else if (this.store.types.values.contains(c.left)) {
        this.cs.constraints.forEach((c1) {
          c1.left = substitute(c1.left, c.right, c.left);
          c1.right = substitute(c1.right, c.right, c.left);
        });
      }
      else {
        this.cs.constraints.forEach((c1) {
          c1.left = substitute(c1.left, c.left, c.right);
          c1.right = substitute(c1.right, c.left, c.right);
        });
      }
    }
    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    We substitute constraints with type variables that appear in only one constraint
    at left or right directly
     */
    log.shout("Step 1");
    for (int i = this.store.varIndex; i >= 0; i--) {
      var constraintsWhere = this.cs.constraints.where((c) {
        IType left = c.left, right = c.right;
        return  (left is TVar && left.index == i && !this.store.types.containsValue(left)) || (right is TVar && right.index == i && !this.store.types.containsValue(right));
      });
      if (constraintsWhere.length == 1) {
        Constraint cons = constraintsWhere.first;
        this.cs.constraints.remove(cons);
        IType left = cons.left;
        IType right = cons.right;
        IType from, to;
        if (left is TVar && left.index == i) {
          from = left;
          to = right;
        }
        else {
          from = right;
          to = left;
        }
        for (Constraint c in this.cs.constraints) {
          c.left = substitute(c.left, from, to);
          c.right = substitute(c.right, from, to);
          this.store.types.forEach((i, t) {
            this.store.types[i] = substitute(t, from, to);
          });
        }

      }
    }


    /*
    Remove dummy constraints
     */
    this.cs.constraints.removeWhere((Constraint c) => (c is SubtypingConstraint) && ((c.left is Bot) || (c.right is Top)));

    /*
    We check the constraint set.
     */
    checkConstraintsOnConstraintSet();

    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    We generate a map from the type variables to every constraint that has the
    type variable
     */
    log.shout("Step 2");
    groupedConstraints = new Map();
    for (Constraint c in this.cs.constraints) {
      IType right = c.right;
      IType left = c.left;
      if (left is TVar) {
        if (!groupedConstraints.containsKey(left)) groupedConstraints[left] = new Set<Constraint>();
        groupedConstraints[left].add(c);
      }
      if (right is TVar) {
        if (!groupedConstraints.containsKey(right)) groupedConstraints[right] = new Set<Constraint>();
        groupedConstraints[right].add(c);
      }
    }
    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    Now, we look in descending order for type variables that are not in the
    grouped constraint map, and replace them with their default value
     */
    log.shout("Step 3");
    for (int i = this.store.varIndex; i >= 0; i--) {
      if (groupedConstraints.keys.where((TVar t) => t.index == i).isEmpty) {
        for (Constraint c in this.cs.constraints) {
          var tVars = searchTVar(c.right, i);
          if (tVars.isNotEmpty)
            c.right = substitute(c.right, tVars.first, tVars.first.defaultType);
        }
        for (int m in this.store.types.keys) {
          var tVars = searchTVar(this.store.types[m], i);
          if (tVars.isNotEmpty)
            this.store.types[m] = substitute(this.store.types[m], tVars.first, tVars.first.defaultType);
        }
      }
    }

    /*
    We iterate over the sets of the groupedConstraints map and reduce them.
     */
    log.shout("Step 4");
    this.cs.constraints.removeWhere((c) => true);
    groupedConstraints.forEach((tvar, set) {
      reduceConstraints(tvar, set);
    });

    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");


    /*
    We do the join and meet operations on resolved JoinTypes and MeetTypes
     */
    log.shout("Step 5");
    groupedConstraints.forEach((tvar, set) {
      resolveTypesInSet(set);
    });

    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    We Iterate over every resolved constraint, substitute everywhere in constraints,
    do the "resolve" operation and repeat, until no resolved constraint are left.
    The resolved constraints should be added to a list.
     */
    log.shout("Step 6");
    substituteWhereUntilEmpty((Constraint c) => c.isResolved() && (c.left.isVariable() || c.right.isVariable()), replaceLeft: true);

    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    Now, we check for invalid constraints to report errors.
     */

    log.shout("Step 7");
    checkConstraintsOnGroupedSet();

    /*
    Finally, we substitute in the store.
     */

    log.shout("Step 8");
    store.types.forEach((i, t) {
      if (groupedConstraints.containsKey(t)) {
        IType selected;
        groupedConstraints[t].forEach((c) {
          if (c.left == t) selected = c.right;
          else selected = c.left;
        });
        store.types[i] = selected;
      }
    });

    store.elements.forEach((e,i) {
      if (!store.getType(e).isConcrete())
        collector.errors.add(new UnableToResolveError(e));
      else {
        if (!AnnotationHelper.elementHasDeclared(e))
          try {
            if (!e.isSynthetic) collector.errors.add(
                new InferredFacetInfo(e, store.getType(e)));
          }
          catch (e) {}
      }
    });
  }

  void substituteWhereUntilEmpty(test, {bool replaceLeft = false}) {
    /*
    1- Select the constraints in this.cs.constraints that satisfy test.
    2- Substitute in every set and in this.cs.constraints.
    3- Go to step 1, unless there is no constraint that satisfy test.
     */
    List<Constraint> allConstraint = groupedConstraints.values.map((s) => s.toList()).expand((x) => x).toList();
    List<Constraint> filter = allConstraint.where(test).toList();
    while (filter.isNotEmpty) {
      Constraint pop = filter.removeLast();
      for (Constraint c in allConstraint) {
        if (c != pop) {
          if (pop.left.isVariable()) {
            IType oldRight = c.right;
            IType oldLeft = c.left;
            IType newRight = substitute(c.right, pop.left, pop.right);
            IType newLeft = substitute(c.left, pop.left, pop.right);
            if (oldRight != newRight) {
              c.location.insertAll(0,pop.location);
              c.isFromMethodInvocation = c.isFromMethodInvocation || pop.isFromMethodInvocation;
            }
            c.right = newRight;
            if (replaceLeft) {
              if (oldLeft != newLeft) {
                c.location.addAll(pop.location);
                c.isFromMethodInvocation = c.isFromMethodInvocation || pop.isFromMethodInvocation;
              }
              c.left = newLeft;
            }
          }
          else {
            IType oldRight = c.right;
            IType oldLeft = c.left;
            IType newRight = substitute(c.right, pop.right, pop.left);
            IType newLeft = substitute(c.left, pop.right, pop.left);
            if (oldRight != newRight) {
              c.location.insertAll(0,pop.location);
            }
            c.right = newRight;
            if (replaceLeft) {
              if (oldLeft != newLeft) {
                c.isFromMethodInvocation = c.isFromMethodInvocation || pop.isFromMethodInvocation;
                c.location.addAll(pop.location);
              }
              c.left = newLeft;
            }
          }
        }
      }
      allConstraint.remove(pop);
      allConstraint.forEach(substituteForDartCoreType);
      groupedConstraints.values.forEach((s) => resolveTypesInSet(s));
      filter = allConstraint.where(test).where((Constraint c) => !(c.left is Bot) && !(c.right is Top)).toList();
    }
  }

  void substituteForDartCoreType(Constraint c) {
    for (int i = 0; i < store.varIndex; i++) {
      c.left = substituteTVarForDartCoreType(c.left, i);
      c.right = substituteTVarForDartCoreType(c.right, i);
    }
  }

  IType substituteTVarForDartCoreType(IType source, int index) {
    if (source is TVar) {
      if (source.index == index && source.dartCoreType != null) {
        return source.dartCoreType;
      }
      else return source;
    }
    else if (source is ArrowType) {
      List<IType> left = source.leftSide.map((p) => substituteTVarForDartCoreType(p, index)).toList();
      IType right = substituteTVarForDartCoreType(source.rightSide, index);
      return new ArrowType(left.toList(), right);
    }
    else if (source is FieldType) {
      IType right = substituteTVarForDartCoreType(source.rightSide, index);
      return new FieldType(right);
    }
    else if (source is Top) return source;
    else if (source is Bot) return source;
    else if (source is ObjectType) {
      Map members = source.members.map((label, arrowType) => new MapEntry(label, substituteTVarForDartCoreType(arrowType, index)));
      return new ObjectType(members);
    }
    else if (source is JoinType) {
      List<IType> types = source.types.map((t) => substituteTVarForDartCoreType(t, index)).toList();
      return new JoinType(types);
    }
    else if (source is MeetType) {
      List<IType> types = source.types.map((t) => substituteTVarForDartCoreType(t, index)).toList();
      return new MeetType(types);
    }
    return source;
  }

  IType substitute(IType source, IType target, IType newType) {
    if (source.equals(target)) return newType;
    else {
      if (source is ArrowType) {
        List<IType> left = source.leftSide.map((p) => substitute(p, target, newType)).toList();
        IType right = substitute(source.rightSide, target, newType);
        return new ArrowType(left.toList(), right);
      }
      else if (source is FieldType) {
        IType right = substitute(source.rightSide, target, newType);
        return new FieldType(right);
      }
      else if (source is Top) return source;
      else if (source is Bot) return source;
      else if (source is ObjectType) {
        Map members = source.members.map((label, arrowType) => new MapEntry(label, substitute(arrowType, target, newType)));
        return new ObjectType(members);
      }
      else if (source is JoinType) {
        List<IType> types = source.types.map((t) => substitute(t, target, newType)).toList();
        return new JoinType(types);
      }
      else if (source is MeetType) {
        List<IType> types = source.types.map((t) => substitute(t, target, newType)).toList();
        return new MeetType(types);
      }
      else return source;
    }
  }

  List<TVar> searchTVar(IType source, int index) {
    List<TVar> ret = new List();
    if (source is TVar && source.index == index) ret.add(source);
    else if (source is ArrowType) {
      for (IType p in source.leftSide) {
        var s1 = searchTVar(p, index);
        ret.addAll(s1);
      }
      var s2 = searchTVar(source.rightSide, index);
      ret.addAll(s2);
    }
    else if (source is ObjectType) {
      for (IType p in source.members.values) {
        ret.addAll(searchTVar(p, index));
      }
    }
    return ret;
  }

  void checkConstraintsOnConstraintSet() {
    this.cs.constraints.forEach((c) {
      if (!c.isValid()) {
        c.location.forEach((l) { if (!locationsWithErrors.contains(l)) locationsWithErrors.add(l); collector.errors.add(new SubtypingError(c, l));}
        );}
    });
  }

  void checkConstraintsOnGroupedSet() {
    this.groupedConstraints.values.forEach((s) => s.forEach((c) {
      if (!c.isValid()) {
        c.location.forEach((l) { if (!locationsWithErrors.contains(l)) locationsWithErrors.add(l); collector.errors.add(new SubtypingError(c, l));}
        );}
    }));
  }

  void resolveTypesInSet(Set<Constraint> set) {
    set.forEach((c) {
      c.left = resolveTypesInType(c.left);
      c.right = resolveTypesInType(c.right);
    });
  }

  IType resolveTypesInType(IType t) {
    if (t is MeetType) {
      if (t.types.any((t1) => t1 is Bot)) {
        return new Bot();
      }
      else if (!t.isConcrete()) return t;
      return t.types.reduce(meet);
    }
    if (t is JoinType) {
      if (t.types.any((t1) => t1 is Top)) {
        return new Top();
      }
      else if (!t.isConcrete()) return t;
      else return t.types.reduce(join);
    }
    return t;
  }

  void reduceConstraints(TVar tvar, Set<Constraint> set) {
    if (set.isEmpty) return;
    Set<Constraint> subtypingSet = set.where((c) => c.left == tvar).toSet();
    Set<Constraint> supertypingSet = set.where((c) => c.right == tvar).toSet();
    Constraint subtypingConstraint, supertypingConstraint;

    if (subtypingSet.isNotEmpty) subtypingConstraint = new SubtypingConstraint(
        tvar,
        new MeetType(subtypingSet.map((c) {
          return c.right;
        }).toList()),
        subtypingSet.map((c2) => c2.location).expand((i) => i).toList(),
    isFromMethodInvocation: subtypingSet.map((c1) => c1.isFromMethodInvocation).reduce((b1, b2) => b1 || b2));

    if (supertypingSet.isNotEmpty) supertypingConstraint = new SubtypingConstraint(
        new JoinType(supertypingSet.map((c) {
          return c.left;
        }).toList()),
        tvar,
        supertypingSet.map((c2) => c2.location).expand((i) => i).toList(),
        isFromMethodInvocation: supertypingSet.map((c1) => c1.isFromMethodInvocation).reduce((b1, b2) => b1 || b2));

    set.retainAll([]);

    if (subtypingConstraint != null) {
      set.add(subtypingConstraint);
      this.cs.addConstraint(subtypingConstraint);
    }
    if (supertypingConstraint != null) {
      set.add(supertypingConstraint);
      this.cs.addConstraint(supertypingConstraint);
    }
  }
}
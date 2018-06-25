import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class ConstraintSolver {
  final Logger log = new Logger("ConstraintSolver");
  ConstraintSet cs;
  Store store;
  ErrorCollector collector;
  Map<TVar, Set<Constraint>> groupedConstraints;

  ConstraintSolver(this.store, this.cs, this.collector);

  void solve() {
    /*
    If there is no type variable to solve, return
     */
    if (this.store.varIndex < 1) return;

    /*
    First, we remove "dummy" constraints like Bot <: x or x <: Top
     */
    log.shout("Step 1");
    this.cs.constraints.removeWhere((Constraint c) => (c is SubtypingConstraint) && ((c.left is Bot) || (c.right is Top)));

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
      return (this.cs.constraints.any((c2) => c.left == c2.right && c.right == c2.left));
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

    /*
    We check for invalid constraints, and remove them
     */
    this.cs.constraints.forEach((c) {
      if (!c.isValid()) collector.errors.add(new SubtypingError(c));
    });

    this.cs.constraints.removeWhere((c) => !c.isValid());


    /*
    We generate a map from the type variables to every constraint that has the
    type variable
     */
    log.shout("Step 2");
    groupedConstraints = new Map();
    for (Constraint c in this.cs.constraints) {
      IType left = c.left;
      if (left is TVar) {
        if (!groupedConstraints.containsKey(left)) groupedConstraints[left] = new Set<Constraint>();
        groupedConstraints[left].add(c);
      }
    }
    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");
    /*
    Now, we look in descending order for type variables that are not in the
    groupedConstraints map, and replace them with their default values.
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
    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    Now, we iterate over all declared constraint that are resolved and replace them in
    the groupedConstraints map, until no declared constraint are left
     */

    log.shout("Step 4");
    substituteWhereUntilEmpty((c) => (c is DeclaredConstraint) && c.isResolved() && c.left.isVariable(), replaceLeft: true);
    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    Then, we replace the resolved constraints resulted from the previous step
     */
    log.shout("Step 5");
    substituteWhereUntilEmpty((Constraint c) => c.isResolved() && c.left.isVariable() && groupedConstraints[c.left].length == 1);
    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    We check for invalid constraints, and remove them
     */
    this.cs.constraints.forEach((c) {
      if (!c.isValid()) collector.errors.add(new SubtypingError(c));
    });

    this.cs.constraints.removeWhere((c) => !c.isValid());
    this.groupedConstraints.values.forEach((s) {
      s.removeWhere((c) => !c.isValid());
    });

    /*
    Now we reduce the groups in the groupedConstraints
    map to only one constraint, doing the replacement and iterating until every
    entry of the map has only one constraint.

    Here, we use the lattice operations when needed:

    - If t1 <: t2 and t1 <: t3 then t1 <: join(t2, t3)
    - If t2 <: t1 and t3 <: t1 then t1 <: meet(t2, t3)
     */

    log.shout("Step 6");
    groupedConstraints.forEach((tvar, set) {
      reduceConstraints(set);
    });
    log.shout("\n groupedConstraints: \n${groupedConstraints}");
    log.shout("\n constraintSet: \n${this.cs.constraints}");

    /*
    Then, we replace the resolved constraints resulted from the previous step
     */
    log.shout("Step 5 again");
    substituteWhereUntilEmpty((Constraint c) => c.isResolved() && c.left.isVariable() && groupedConstraints[c.left].length == 1);

    /*
    Finally, we do a replacement in the store, and look for type variables in
    the store that are not in the groupedConstraints map, and replace them with
    their default value.
     */

    log.shout("\n groupedConstraints: \n${groupedConstraints}");

    store.types.forEach((i, t) {
      if (groupedConstraints.containsKey(t) && groupedConstraints[t].length == 1 && groupedConstraints[t].first.isResolved())
        store.types[i] = groupedConstraints[t].first.right;
    });

    /*
    We do a final look in the store to generate the "INFO" errors to acknowledge
    the user about the inference result.
     */

    store.elements.forEach((e,i) {
      if (store.getType(e).isVariable()) collector.errors.add(new UnableToResolveError(e));
      else {
        if (!AnnotationHelper.elementHasDeclared(e))
          collector.errors.add(new InferredFacetInfo(e, store.getType(e)));
      }
    });

  }

  void substituteWhereUntilEmpty(test, {bool replaceLeft = false}) {
    /*
    1- Select the constraints in this.cs.constraints that satisfy test.
    2- Substitute in every set and in this.cs.constraints.
    3- Go to step 1, unless there is no constraint that satisfy test.
     */
    List<Constraint> filter = this.cs.constraints.where(test).toList();
    while (filter.isNotEmpty) {
      Constraint pop = filter.removeLast();
      for (Constraint c in this.cs.constraints) {
        if (c != pop) {
          c.right = substitute(c.right, pop.left, pop.right);
          if (replaceLeft) c.left = substitute(c.left, pop.left, pop.right);
        }
      }
      this.cs.constraints.remove(pop);
      filter = this.cs.constraints.where(test).toList();
    }
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

  void reduceConstraints(Set<Constraint> set) {
    this.cs.constraints.removeWhere((c) => set.contains(c));
    Constraint newConstraint = set.reduce((c1,c2) {
      if (!(c1.right is ObjectType)) {
        log.shout("Hubo un error al intentar reducir ${c1} pues su lado derecho es variable");
        collector.errors.add(new SubtypingError(c1));
        return c2;
      }
      if (!(c2.right is ObjectType)) {
        log.shout("Hubo un error al intentar reducir ${c2} pues su lado derecho es variable");
        collector.errors.add(new SubtypingError(c2));
        return c1;
      }
      if (!c1.isValid()) {
        log.shout("Hubo un error pues ${c1} no es válida");
        collector.errors.add(new SubtypingError(c1));
      }
      if (!c2.isValid()) {
        log.shout("Hubo un error pues ${c2} no es válida");
        collector.errors.add(new SubtypingError(c2));
      }
      return meetConstraint(c1, c2);
    });
    set.retainAll([]);
    set.add(newConstraint);
    this.cs.constraints.add(newConstraint);
  }
}
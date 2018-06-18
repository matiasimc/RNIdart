import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class ConstraintSolver {
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
    We generate a map from the type variables to every constraint that has the
    type variable
     */
    groupedConstraints = new Map();
    for (Constraint c in this.cs.constraints) {
      IType left = c.left;
      if (left is TVar) {
        if (!groupedConstraints.containsKey(left)) groupedConstraints[left] = new Set<Constraint>();
        groupedConstraints[left].add(c);
      }
    }

    /*
    We iterate over all declared constraint that are resolved and replace them in
    the groupedConstraints map, and iterate until no declared constraint are left
     */

    List<Constraint> declaredAndResolved =
      this.cs.constraints.where((c) => c is DeclaredConstraint && c.isResolved());

    while (declaredAndResolved.isNotEmpty) {
      for (Constraint c in declaredAndResolved) {
        this.groupedConstraints.forEach((tvar, set) {
          set.forEach((sourceConstraint) => substitute(sourceConstraint.right, c.left, c.right));
        });
      }
      this.cs.constraints.removeWhere((c) => declaredAndResolved.contains(c));
      groupedConstraints.values.forEach((set) => set.removeWhere((c) => declaredAndResolved.contains(c)));
      declaredAndResolved =
          this.cs.constraints.where((c) => c is DeclaredConstraint && c.isResolved());
    }

    /*
    Now, we look in descending order for type variables that are not in the
    groupedConstraints map, and replace them with their default values.
     */
    for (int i = this.store.varIndex; i >= 0; i--) {
      TVar tvari = new TVar(i, null);
      if (!groupedConstraints.containsKey(tvari)) {
        groupedConstraints.values.forEach((set) => set.forEach((c) {
          var tVars = searchTVar(c.right, i);
          if (tVars.isNotEmpty) {
            substitute(c.right, tVars.first, tVars.first.defaultType);
          }
        }));
      }
    }

    /*
    Then, we replace the resolved constraints resulted from the previous step
     */

    /*
    Again in descending order, we reduce the groups in the groupedConstraints
    map to only one constraint, doing the replacement and iterating until every
    entry of the map has only one constraint.

    Here, we use the lattice operations when needed:

    - If t1 <: t2 and t1 <: t3 then t1 <: join(t2, t3)
    - If t2 <: t1 and t3 <: t1 then t1 <: meet(t2, t3)
     */

    /*
    Finally, we do a replacement in the store
     */

  }

  void substitute(IType source, IType target, IType newType) {
    if (source.equals(target)) source = newType;
    else {
      if (source is ArrowType) {
        source.leftSide.forEach((p) => substitute(p, target, newType));
        substitute(source.rightSide, target, newType);
      }
      else if (source is ObjectType) {
        source.members.values.forEach((arrowType) => substitute(arrowType, target, newType));
      }
      else return;
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

}
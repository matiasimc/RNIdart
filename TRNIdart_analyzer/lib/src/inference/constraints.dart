import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'dart:collection';

abstract class Constraint {
  /*
  A constraint is resolved when a type is related to a concrete type
   */
  IType left;
  IType right;
  bool isResolved();
  bool isEmpty();
  bool isValid();
}

class SubtypingConstraint extends Constraint {
  IType left;
  IType right;

  SubtypingConstraint(this.left, this.right);

  @override
  bool isResolved() => this.left.isConcrete() || this.right.isConcrete();

  @override
  bool isEmpty() => false;

  String toString() => "${left} <: ${right}\n";

  bool operator ==(Object o) =>
    (o is SubtypingConstraint && this.left.equals(o.left) && this.right.equals(o.right));

  @override
  bool isValid() => this.left.subtypeOf(this.right);
}

class DeclaredConstraint extends Constraint {
  IType left;
  IType right;

  DeclaredConstraint(this.left, this.right);

  @override
  bool isResolved() => this.left.isConcrete() || this.right.isConcrete();

  @override
  bool isEmpty() => false;

  String toString() => "${left} = ${right}\n";

  bool operator ==(Object o) =>
      (o is DeclaredConstraint && this.left.equals(o.left) && this.right.equals(o.right));

  @override
  bool isValid() => true;
}

class ConstraintSet {
  List<Constraint> constraints;

  ConstraintSet() {
    this.constraints = new List<Constraint>();
  }

  void addConstraint(Constraint c) {
    this.constraints.add(c);
  }

}
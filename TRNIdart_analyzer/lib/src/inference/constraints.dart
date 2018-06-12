import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'dart:collection';

abstract class Constraint {
  /*
  A constraint is resolved when a type is related to a concrete type
   */
  bool isResolved();
  bool isEmpty();
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
}

class EmptyConstraint extends Constraint {
  @override
  bool isResolved() => true;

  @override
  bool isEmpty() => true;
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
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

abstract class Constraint {
  /*
  A constraint is resolved when a type is related to a concrete type
   */
  IType left;
  IType right;
  List<ErrorLocation> location;
  bool isResolved();
  bool isEmpty();
  bool isValid();
  bool isInvalidMethodInvocation();
  bool isFromMethodInvocation;
  Expression invalidatingExpression;
}

class SubtypingConstraint extends Constraint {
  IType left;
  IType right;
  List<ErrorLocation> location;
  bool isFromMethodInvocation;
  Expression invalidatingExpression;

  SubtypingConstraint(this.left, this.right, this.location, {this.isFromMethodInvocation = false, this.invalidatingExpression});

  @override
  bool isResolved() => this.left.isConcrete() || this.right.isConcrete();

  @override
  bool isEmpty() => false;

  String toString() => "${left} <: ${right}\n";

  bool operator ==(Object o) =>
    (o is SubtypingConstraint && this.left.equals(o.left) && this.right.equals(o.right));

  @override
  bool isValid() => this.isFromMethodInvocation || this.left.subtypeOf(this.right);

  @override
  bool isInvalidMethodInvocation() => (this.isFromMethodInvocation && !this.left.subtypeOf(this.right));
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
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
}

class SubtypingConstraint extends Constraint {
  IType left;
  IType right;
  List<ErrorLocation> location;
  bool isFromMethodInvocation;

  SubtypingConstraint(this.left, this.right, this.location, [this.isFromMethodInvocation = false]);

  @override
  bool isResolved() => this.left.isConcrete() || this.right.isConcrete();

  @override
  bool isEmpty() => false;

  String toString() => "${left} <: ${right}\n";

  bool operator ==(Object o) =>
    (o is SubtypingConstraint && this.left.equals(o.left) && this.right.equals(o.right));

  @override
  bool isValid() {
    if (isFromMethodInvocation) {
      if (this.left is Closed) return false;
      else return true;
    }
    if (this.left is Closed && this.right is Closed) return false;
    if (left is Closed) return left.getType().subtypeOf(right);
    if (right is Closed) return left.subtypeOf(right.getType());
    return left.subtypeOf(right);
  }
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
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

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
  bool isResolved() {
    return this.left.isConcrete() || this.right.isConcrete();
  }

  @override
  bool isEmpty() => false;
}

class EmptyConstraint extends Constraint {
  @override
  bool isResolved() => true;

  @override
  bool isEmpty() => true;
}

class ConstraintSet {
  Constraint head;
  ConstraintSet tail;

  ConstraintSet(this.head, this.tail);

}
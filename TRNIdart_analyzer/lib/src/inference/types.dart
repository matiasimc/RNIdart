abstract class  IType {
  bool isConcrete();
}

class TVar extends IType {
  int index;
  IType defaultType;

  @override
  bool isConcrete() => false;

  TVar(this.index, this.defaultType);

  String toString() => "TVar(${this.index})";
}

class ObjectType extends IType {
  /*
  A map between a label and a type (usually arrow type)
   */
  Map<String, ArrowType> members;

  ObjectType([this.members]) {
    if (this.members == null) this.members = new Map<String, ArrowType>();
  }

  @override
  bool isConcrete() {
    for (IType t in this.members.values) {
      if (!t.isConcrete()) return false;
    }
    return true;
  }

  void addMember(String label, IType type) {
    this.members[label] = type;
  }

  String toString() => "${members}";
}

class ArrowType extends IType {
  List<IType> leftSide;
  IType rightSide;

  ArrowType(this.leftSide, this.rightSide);

  @override
  bool isConcrete() {
    if (!this.rightSide.isConcrete()) return false;
    for (IType t in leftSide) {
      if (!t.isConcrete()) return false;
    }
    return true;
  }

  String toString() => "${leftSide} -> ${rightSide}";
}

/*
Should be removed when the interface parser is done. ObjectType should be used
instead.
 */
class DeclaredType extends IType {
  String name;

  DeclaredType(this.name);

  bool isConcrete() => true;

  String toString() => this.name;
}

class Top extends IType {
  @override
  bool isConcrete() => true;

  String toString() => "Top";
}

class Bot extends IType {
  @override
  bool isConcrete() => true;

  String toString() => "Bot";
}
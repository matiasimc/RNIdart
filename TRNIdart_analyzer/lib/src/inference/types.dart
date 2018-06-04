abstract class  IType {
  bool isConcrete();
}

class TVar extends IType {
  int index;

  @override
  bool isConcrete() => false;

  TVar(this.index);
}

class ObjectType extends IType {
  /*
  A map between a label and a type (usually arrow type)
   */
  Map<String, IType> members;

  ObjectType([this.members]) {
    if (this.members == null) this.members = new Map<String, IType>();
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
}

class Top extends IType {
  @override
  bool isConcrete() => true;
}

class Bot extends IType {
  @override
  bool isConcrete() => true;
}
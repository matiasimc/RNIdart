abstract class  IType {
  bool isConcrete();
  bool equals(IType t);
}

class TVar extends IType {
  int index;
  IType defaultType;

  @override
  bool isConcrete() => false;

  TVar(this.index, this.defaultType);

  String toString() => "TVar(${this.index})";

  bool equals(IType t) {
    if (t is TVar) {
      return this.index == t.index;
    }
    return false;
  }

  bool operator ==(o) => o is TVar && this.index == o.index;
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

  bool equals(IType t) {
    bool ret = true;
    if (t is ObjectType) {
      this.members.forEach((label, type) {
        if (!t.members.containsKey(label)) return false;
        ret = ret && t.members[label].equals(this.members[label]);
      });
    }
    else ret = false;
    return ret;
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

  String toString() => "${leftSide} -> ${rightSide}";

  bool equals(IType t) {
    if (t is ArrowType) {
      if (!rightSide.equals(t.rightSide)) return false;
      if (leftSide.length != t.leftSide.length) return false;
      for (int i = 0; i < leftSide.length; i++) {
        if (!leftSide[i].equals(t.leftSide[i])) return false;
      }
    }
    else return false;
    return true;
  }
}

class Top extends ObjectType {
  @override
  bool isConcrete() => true;

  String toString() => "Top";

  bool equals(IType t) => t is Top;
}

class Bot extends ObjectType {
  @override
  bool isConcrete() => true;

  String toString() => "Bot";

  bool equals(IType t) => t is Bot;
}
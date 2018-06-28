import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

SubtypingConstraint meetConstraint(Constraint c1, Constraint c2) {
  return new SubtypingConstraint(c1.left, meet(c1.right, c2.right), c1.location);
}

SubtypingConstraint joinConstraint(Constraint c1, Constraint c2) {
  return new SubtypingConstraint(join(c1.left, c2.left), c1.right, c1.location);
}

ObjectType meet(IType t1, IType t2) {
  if (t1 is Bot) return t1;
  if (t2 is Bot) return t2;
  if (t1 is Top) return t2;
  if (t2 is Top) return t1;
  ObjectType t = new ObjectType();
  if (t1 is ObjectType) t1.members.forEach((label, arrowType) => t.addMember(label, arrowType));
  if (t2 is ObjectType) t2.members.forEach((label, arrowType) => t.addMember(label, arrowType));
  return t;
}

ObjectType join(IType t1, IType t2) {
  if (t1 is Bot) return t2;
  if (t2 is Bot) return t1;
  if (t1 is Top) return t1;
  if (t2 is Top) return t2;
  ObjectType t = new ObjectType();
  if (t1 is ObjectType) t1.members.forEach((l1, at1) {
    if (t2 is ObjectType && t2.members.containsKey(l1)) {
      if (at1.equals(t2.members[l1])) t.addMember(l1, at1);
    }
  });
  return t;
}
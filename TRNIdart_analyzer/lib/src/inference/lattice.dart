import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

SubtypingConstraint joinConstraint(Constraint c1, Constraint c2) {
  return new SubtypingConstraint(c1.left, join(c1.right, c2.right));
}

ObjectType join(ObjectType t1, ObjectType t2) {
  if (t1 is Bot) return t1;
  if (t2 is Bot) return t2;
  if (t1 is Top) return t2;
  if (t2 is Top) return t1;
  ObjectType t = new ObjectType();
  t1.members.forEach((label, arrowType) => t.addMember(label, arrowType));
  t2.members.forEach((label, arrowType) => t.addMember(label, arrowType));
  return t;
}

ObjectType meet(ObjectType t1, ObjectType t2) {
  if (t1 is Bot) return t2;
  if (t2 is Bot) return t1;
  if (t1 is Top) return t1;
  if (t2 is Top) return t2;
  ObjectType t = new ObjectType();
  t1.members.forEach((l1, at1) {
    if (t2.members.containsKey(l1)) {
      if (at1.equals(t2.members[l1])) t.addMember(l1, at1);
    }
  });
  return t;
}
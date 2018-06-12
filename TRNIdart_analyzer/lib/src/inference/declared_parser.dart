import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class DeclaredParser extends SimpleAstVisitor {

  IType _type;

  IType getType() => this._type;

  @override
  visitClassDeclaration(ClassDeclaration node) {
    Logger.root.shout("Faceta declarada ${node.name}");
    if (node.element.name == "Top") _type = new Top();
    else if (node.element.name == "Bot") _type = new Bot();
    else {
      ObjectType ot = new ObjectType();
      for (ClassMember m in node.members) {
        IType signature;
        String label;
        if (m is MethodDeclaration) {
          signature = new ArrowType(m.parameters.parameters.map((p) => new Top()).toList(), new Bot());
          label = m.name.toString();
        }
        if (m is FieldDeclaration) {
          signature = new Bot();
          label = m.element.name;
        }
        ot.addMember(label, signature);
      }
      _type = ot;
    }
  }
}
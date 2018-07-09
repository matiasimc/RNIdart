import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class FirstDeclaredVisitor extends SimpleAstVisitor {
  Map<String, Element> abstractClasses;

  FirstDeclaredVisitor(this.abstractClasses);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    abstractClasses[node.element.name] = node.element;
  }
}

class SecondDeclaredVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("SecondDeclaredVisitor");
  Map<String, IType> declaredStore;
  Map<String, Element> abstractClasses;
  IType CORE_PARAMETER_FACET;
  IType CORE_RETURN_FACET;

  SecondDeclaredVisitor(this.declaredStore, this.abstractClasses, this.CORE_PARAMETER_FACET, this.CORE_RETURN_FACET);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    Logger.root.shout("Faceta declarada ${node.name}");
    if (declaredStore.containsKey(node.name)) return;
    ObjectType ot = new ObjectType();
    for (ClassMember m in node.members) {
      String label = "";
      IType signature;
      if (m is MethodDeclaration) {
        label = m.name.toString();
        List<IType> left;
        if (m.parameters != null) left = m.parameters.parameters.map((p) {
          if (AnnotationHelper.elementHasDeclared(p.element)) {
            Annotation a = AnnotationHelper.getDeclaredForParameter(p);
            String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
            if (abstractClasses.containsKey(facet)) abstractClasses[facet].computeNode().accept(this);
            IType typeP = declaredStore.containsKey(facet) ? declaredStore[facet] : CORE_PARAMETER_FACET;
            return typeP;
          }
          else return CORE_PARAMETER_FACET;
        }).toList();
        IType right = CORE_RETURN_FACET;
        Annotation a = AnnotationHelper.getDeclared(m);
        if (a != null) {
          String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
          if (abstractClasses.containsKey(facet)) abstractClasses[facet].computeNode().accept(this);
          right = declaredStore.containsKey(facet) ? declaredStore[facet] : CORE_PARAMETER_FACET;
        }
        signature = left != null ? new ArrowType(left, right) : new FieldType(right);
      }
      if (m is FieldDeclaration) {
        if (m.fields.variables.first != null) label = m.fields.variables.first.element.name;
        IType right = CORE_RETURN_FACET;
        Annotation a = AnnotationHelper.getDeclared(m);
        if (a != null) {
          String facet = a.arguments.arguments.first.toString().replaceAll("\"", "");
          if (abstractClasses.containsKey(facet)) abstractClasses[facet].computeNode().accept(this);
          right = declaredStore.containsKey(facet) ? declaredStore[facet] : CORE_PARAMETER_FACET;
        }
        signature = new FieldType(right);
      }
      ot.addMember(label, signature);
    }
    declaredStore[node.element.name] = ot;
  }
}
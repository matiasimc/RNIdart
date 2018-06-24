import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class AnnotationHelper {
  static Annotation getDeclared(AnnotatedNode node) {
    int index = node.metadata.indexWhere((e) => e.name.toString() == "declared");
    if (index == -1) return null;
    else return node.metadata.elementAt(index);
  }

  static Annotation getDeclaredForParameter(FormalParameter node) {
    int index = node.metadata.indexWhere((e) => e.name.toString() == "declared");
    if (index == -1) return null;
    else return node.metadata.elementAt(index);
  }

  static bool elementHasDeclared(Element e) =>
    e.metadata.any((ElementAnnotation e) => e.toSource().contains("declared"));
}
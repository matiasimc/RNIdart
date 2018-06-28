import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class AnnotationHelper {
  static Annotation getDeclared(AnnotatedNode node) {
    Annotation ret;
    try {
      int index = node.metadata.indexWhere((e) => e.name.toString() == "S");
      if (index == -1) return null;
      if (node.metadata.elementAt(index).arguments.arguments.isEmpty) return null;
      else return node.metadata.elementAt(index);
    }
    catch(e){}
    return ret;
  }

  static Annotation getDeclaredForParameter(FormalParameter node) {
    Annotation ret;
    try {
      int index = node.metadata.indexWhere((e) => e.name.toString() == "S");
      if (index == -1) return null;
      if (node.metadata.elementAt(index).arguments.arguments.isEmpty) return null;
      else return node.metadata.elementAt(index);
    }
    catch(e){}
    return ret;
  }

  static bool elementHasDeclared(Element e) {
    bool ret = false;
    try {
      ret = e.metadata.any((ElementAnnotation e) => e.toSource().contains("S"));
    }
    catch(e) {

    }
    return ret;
  }

}
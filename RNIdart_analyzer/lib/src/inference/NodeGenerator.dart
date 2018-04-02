import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';

class NodeGenerator extends RecursiveAstVisitor {

  AstNode newNode;

  FormalParameter generateParameter(FormalParameter node, String abstractClassName) {
    String code = "void foo(@interface(${abstractClassName}) ${node.element.type} ${node.element.name}) {}";
    new StringAnalyzer(code).acceptForAll(this);
    return this.newNode;
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    this.newNode = node;
  }
}
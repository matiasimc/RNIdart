import 'package:analyzer/analyzer.dart';

class ListAllNodesVisitor extends GeneralizingAstVisitor {

  ListAllNodesVisitor() {

  }

  @override
  visitNode(AstNode node) {
    var lines = <String>['\t${node.runtimeType} : <"$node">, my parent is ${node.parent.runtimeType} : <"${node.parent}">'];
    print(lines.join('\n'));
    if (node is FormalParameter) {
      print(node.element.type);
    }
    return super.visitNode(node);
  }
}
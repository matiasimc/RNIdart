import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class LabelVisitor extends RecursiveAstVisitor {

  ErrorCollector errorCollector;

  LabelVisitor(this.errorCollector);

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
      new AnalysisError(node.variables[0].element.source, node.offset, node.length, new UndefinedInterface(node.toSource()))
    );
    return super.visitVariableDeclarationList(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new AnalysisError(node.element.source, node.offset, node.length, new UndefinedInterface(node.toSource()))
    );
    return super.visitMethodDeclaration(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new AnalysisError(node.element.source, node.offset, node.length, new UndefinedInterface(node.toSource()))
    );
    return super.visitFunctionDeclaration(node);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new AnalysisError(node.element.source, node.offset, node.length, new UndefinedInterface(node.toSource()))
    );
    return super.visitTopLevelVariableDeclaration(node);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new AnalysisError(node.element.source, node.offset, node.length, new UndefinedInterface(node.toSource()))
    );
    return super.visitFieldDeclaration(node);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new AnalysisError(node.element.source, node.offset, node.length, new UndefinedInterface(node.toSource()))
    );
    return super.visitSimpleFormalParameter(node);
  }
}
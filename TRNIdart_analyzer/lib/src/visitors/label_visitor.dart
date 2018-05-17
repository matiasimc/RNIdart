import 'dart:io';

import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class LabelVisitor extends RecursiveAstVisitor {


  final Logger log = new Logger("LabelVisitor");
  ErrorCollector errorCollector;

  LabelVisitor(this.errorCollector);

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    log.shout("Visit variables declaration ${node.variables}\n");
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
      new UndefinedInterfaceError(node.variables[0].element.source, node.offset, node.length, null, node.toSource())
    );
    return super.visitVariableDeclarationList(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    log.shout("Visit method declaration ${node.element}\n");
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new UndefinedInterfaceError(node.element.source, node.offset, node.length, null, node.toSource())
    );
    return super.visitMethodDeclaration(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    log.shout("Visit function declaration ${node.element}\n");
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new UndefinedInterfaceError(node.element.source, node.offset, node.length, null, node.toSource())
    );
    return super.visitFunctionDeclaration(node);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    log.shout("Visit top level variable declaration ${node.element}\n");
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new UndefinedInterfaceError(node.element.source, node.offset, node.length, null, node.toSource())
    );
    return super.visitTopLevelVariableDeclaration(node);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    log.shout("Visit field declaration ${node.element}\n");
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new UndefinedInterfaceError(node.element.source, node.offset, node.length, null, node.toSource())
    );
    return super.visitFieldDeclaration(node);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    log.shout("Visit parameter ${node.element}\n");
    bool hasInterface = node.metadata.map((a) => a.name == "interface").isNotEmpty;
    if (!hasInterface) errorCollector.errors.add(
        new UndefinedInterfaceError(node.element.source, node.offset, node.length, null, node.toSource())
    );
    return super.visitSimpleFormalParameter(node);
  }
}
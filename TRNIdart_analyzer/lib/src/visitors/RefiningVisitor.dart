import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class RefiningVisitor extends SimpleAstVisitor {
  GlobalEnvironment env;

  final Logger log = new Logger("RootVisitor");

  RefiningVisitor() {
    this.env = new GlobalEnvironment();
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    log.shout("Start processing compilation unit ${node.hashCode}");
    node.visitChildren(new CompilationUnitVisitor(this.env));
  }

}
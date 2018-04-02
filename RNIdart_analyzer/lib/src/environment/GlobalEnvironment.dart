/*
This class manages the class, function and global variable definitions.
 */
import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';

class GlobalEnvironment {
  Map<String, ClassElement> classes;
  Map<String, FunctionElement> functions;
  Map<VariableDeclaration, Usage> variablesUsage;
  /* note: I added the variables map because I was unable to get the global
    variable declaration AST node from a local context
  */
  Map<String, VariableDeclaration> variables;
  List<LocalEnvironment> localEnvs;

  GlobalEnvironment() {
    this.classes = new Map<String, ClassElement>();
    this.functions = new Map<String, FunctionElement>();
    this.variables = new Map<String, VariableDeclaration>();
    this.variablesUsage = new Map<VariableDeclaration, Usage>();
    this.localEnvs = new List<LocalEnvironment>();
  }
}
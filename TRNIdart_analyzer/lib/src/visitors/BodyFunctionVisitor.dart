import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class BodyFunctionVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("BodyFunctionVisitor");
  LocalEnvironment localEnv;
  GlobalEnvironment env;
  FunctionElement function;

  BodyFunctionVisitor(GlobalEnvironment env, LocalEnvironment localEnv, FunctionElement function) {
    this.localEnv = localEnv;
    this.env = env;
    this.function = function;
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    log.shout("Variable declaration ${node} found");
    this.localEnv.variables[node] = new Usage();
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    log.shout("Method invocation ${node} found");
    AstNode target = node.target;
    // If this is a chained call
    if (target is MethodInvocation || target is PrefixedIdentifier) {
      log.shout("Chained call found");
      Usage u = new Usage();
      u.methodCalls.add(node);
      this.localEnv.chainedCalls[target] = u;
    }

    // TODO refine the type of the arguments

    // If target is a variable
    if (target is SimpleIdentifier) {
      // If it's a parameter
      if (target.bestElement.computeNode() is FormalParameter) {
        this.function.parameterUsage[target.bestElement.computeNode()].methodCalls.add(node);
      }
      // Else, could be a global variable
      else if (this.env.variables.containsKey(target.name)) {
        this.env.variablesUsage[this.env.variables[target.name]].methodCalls.add(node);
      }
      // Or a local one
      else if (target.bestElement.computeNode() is VariableDeclaration) {
        this.localEnv.variables[target.bestElement.computeNode()].methodCalls.add(node);
      }
    }
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    log.shout("Field invocation ${node} found");
    AstNode target = node.prefix;
    // If target is a chained call
    if (target is MethodInvocation || target is PrefixedIdentifier) {
      log.shout("Chained call found");
      Usage u = new Usage();
      u.fieldCalls.add(node);
      this.localEnv.chainedCalls[target] = u;
    }

    // If target is a variable
    if (target is SimpleIdentifier) {
      // If it's a parameter
      if (target.bestElement.computeNode() is FormalParameter) {
        this.function.parameterUsage[target.bestElement.computeNode()].fieldCalls.add(node);
      }
      // Else, could be a global variable
      else if (this.env.variables.containsKey(target.name)) {
        this.env.variablesUsage[this.env.variables[target.name]].fieldCalls.add(node);
      }
      // Or a local one
      else if (target.bestElement.computeNode() is VariableDeclaration){
        this.localEnv.variables[target.bestElement.computeNode()].fieldCalls.add(node);
      }
    }
  }


}
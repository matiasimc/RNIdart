import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class CompilationUnitVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("CompilationUnitVisitor");
  GlobalEnvironment env;

  CompilationUnitVisitor(GlobalEnvironment env) {
    this.env = env;
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    log.shout("Function ${node.name} declaration found");
    if (!this.env.functions.containsKey(node.name.toString())) {
      FunctionElement function = new FunctionElement(node);
      this.env.functions[node.name.toString()] = function;
      node.visitChildren(new FunctionDeclarationVisitor(this.env, function));
    }
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    log.shout("Class ${node.name} declaration found");
    ClassElement classElement;
    if (!this.env.classes.containsKey(node.name.toString())) {
      classElement = new ClassElement(node);
      this.env.classes[node.name.toString()] = classElement;
    }
    else {
      classElement = this.env.classes[node.name.toString()];
    }
    node.visitChildren(new ClassDeclarationVisitor(this.env, classElement));
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    log.shout("Global variable declaration found ${node}");
    node.variables.variables.forEach(
        (v) {
          this.env.variables[v.name.toString()] = v;
          this.env.variablesUsage[v] = new Usage();
        }
    );
  }
}
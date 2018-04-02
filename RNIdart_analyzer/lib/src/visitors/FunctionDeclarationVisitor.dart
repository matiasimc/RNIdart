import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';

class FunctionDeclarationVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("FunctionDeclarationVisitor");
  GlobalEnvironment env;
  FunctionElement function;

  FunctionDeclarationVisitor(GlobalEnvironment env, FunctionElement f) {
    this.env = env;
    this.function = f;
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    log.shout("Processing function parameters ${node}");
    node.parameters.forEach(
        (p) {
          this.function.parameterUsage[p] = new Usage();
        }
    );
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    log.shout("Processing function body ${node}");
    LocalEnvironment localEnv = new LocalEnvironment();
    this.env.localEnvs.add(localEnv);
    node.visitChildren(new BodyFunctionVisitor(this.env, localEnv, this.function));
  }
}
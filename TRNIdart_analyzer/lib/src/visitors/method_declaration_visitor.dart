import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class MethodDeclarationVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("FunctionDeclarationVisitor");
  GlobalEnvironment env;
  MethodElement method;

  MethodDeclarationVisitor(this.env, this.method);

  @override
  visitFormalParameterList(FormalParameterList node) {
    log.shout("Processing method parameters ${node}");
    node.parameters.forEach(
            (p) {
          this.method.parameterUsage[p] = new Usage();
        }
    );
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    log.shout("Processing method body ${node}");
    LocalEnvironment localEnv = new LocalEnvironment();
    this.env.localEnvs.add(localEnv);
    node.visitChildren(new BodyMethodVisitor(this.env, localEnv, this.method));
  }
}
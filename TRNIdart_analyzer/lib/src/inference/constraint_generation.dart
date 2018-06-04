import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class CompilationUnitVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("CompilationUnitVisitor");

  @override
  visitClassDeclaration(ClassDeclaration node) {
    log.shout("Visiting class ${node.name}");
    node.members.accept(new ClassMembersVisitor());
  }
}


class ClassMembersVisitor extends SimpleAstVisitor {
  final Logger log = new Logger("ClassMemberVisitor");

  ClassDeclarationVisitor() {}

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    log.shout("Visiting method ${node.name}");
    node.visitChildren(new MethodDeclarationVisitor());
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    log.shout("Visiting field(s) ${node.fields.variables.join(',')}");
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    log.shout("Visiting constructor");
  }
}

class MethodDeclarationVisitor extends RecursiveAstVisitor {
  final Logger log = new Logger("MethodDeclarationVisitor");
  Store store;

  MethodDeclarationVisitor() {
    this.store = new Store();
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    log.shout("Visiting parameter(s) ${node.parameters.join(',')}");
    for (FormalParameter p in node.parameters) {
      Annotation declared = p.metadata.firstWhere((e) => e.name == "declared");
      // TODO parse declared type with function (Annotation -> IType)
      store.addVariable(p.identifier.name);
    }

  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    log.shout("Visiting function body");
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    // TODO add the constraints (target, {m: TVar(x)}) and (TVar(x), TVar(y) -> TVar(z))
  }
}
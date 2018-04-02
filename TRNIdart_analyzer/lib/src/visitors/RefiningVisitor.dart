import 'package:analyzer/analyzer.dart';
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class RefiningVisitor extends SimpleAstVisitor {
  GlobalEnvironment env;

  RefiningVisitor() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time} ${rec.loggerName} -> ${rec.message}');
    });
    this.env = new GlobalEnvironment();
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    Logger.root.shout("Start processing compilation unit ${node.hashCode}");
    node.visitChildren(new CompilationUnitVisitor(this.env));
  }

}
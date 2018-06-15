import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/analyzer.dart' show AnalysisError, CompilationUnit;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'dart:io';

class TRNIAnalyzer {
  static Store store = new Store();
  static ConstraintSet cs = new ConstraintSet();
  static Map<String, IType> declaredStore = new Map();

  static void reset() {
    TRNIAnalyzer.store = new Store();
    TRNIAnalyzer.cs = new ConstraintSet();
    TRNIAnalyzer.declaredStore = new Map();
  }

  static void setUpLogger() {
    File f = new File("TRNI-log.txt");
    f.createSync();
    f.writeAsStringSync("\n\n==== Analysis starts on ${new DateTime.now().toIso8601String()} ====\n\n", mode: FileMode.APPEND);
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      f.writeAsStringSync('${rec.level.name}: ${rec.time} ${rec.loggerName} -> ${rec.message}\n', mode: FileMode.APPEND);
    });
  }

  static List<AnalysisError> computeErrors(CompilationUnit resolvedUnit) {
    Logger.root.shout("Analysis on path: ${resolvedUnit.element.source.uri.path}\n");
    var visitor = new CompilationUnitVisitor(store, cs, declaredStore);
    resolvedUnit.accept(visitor);
    Logger.root.shout("Store: \n${visitor.store.printStore()}");
    Logger.root.shout("Constraint Set: \n${visitor.cs.constraints}");
    ErrorCollector errorCollector = new ErrorCollector();
    //resolvedUnit.accept(new LabelVisitor(errorCollector));
    return errorCollector.errors;
  }

  static void log(String message) {
    Logger.root.shout(message);
  }

}
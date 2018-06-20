import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/analyzer.dart' show AnalysisError, CompilationUnit;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart' hide Logger;
import 'package:analyzer/src/generated/source.dart';

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
    ErrorCollector errorCollector = new ErrorCollector();
    Logger.root.shout("Analysis on path: ${resolvedUnit.element.source.uri.path}\n");
    var visitor = new CompilationUnitVisitor(store, cs, declaredStore);
    resolvedUnit.accept(visitor);
    Logger.root.shout("Store: \n${visitor.store.printStore()}");
    Logger.root.shout("Constraint Set: \n${visitor.cs.constraints}");
    Logger.root.shout("Solving constraints...");
    new ConstraintSolver(store, cs, errorCollector).solve();
    Logger.root.shout("Store: \n${visitor.store.printStore()}");
    Logger.root.shout("Constraint Set: \n${visitor.cs.constraints}");
    //resolvedUnit.accept(new LabelVisitor(errorCollector));
    return errorCollector.errors;
  }

  static List<AnalysisError> computeAllErrors(AnalysisContext context, Source source,  {bool returnDartErrors: true}) {
    LibraryElement libraryElement = context.computeLibraryElement(source);

    //var unit = libraryElement.unit;
    CompilationUnit unit = context.resolveCompilationUnit(source, libraryElement);

    var dartErrors = context.computeErrors(source);
    var badErrors = dartErrors.where((e) =>
    e.errorCode.errorSeverity == ErrorSeverity.ERROR ||
        e.errorCode.errorSeverity == ErrorSeverity.WARNING);
    if (badErrors.length > 0 && returnDartErrors)
      return dartErrors;

    return (computeErrors(unit));
  }

  static void log(String message) {
    Logger.root.shout(message);
  }

}
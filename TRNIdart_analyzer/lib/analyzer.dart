import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/analyzer.dart' show AnalysisError, CompilationUnit;
import 'dart:io' as io show File;
import 'package:path/path.dart' as pathos;
import 'package:analyzer/src/generated/engine.dart' hide Logger;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:cli_util/cli_util.dart' show getSdkPath;
import 'package:TRNIdart_analyzer/analyzer.dart';
import 'dart:io';

class TRNIAnalyzer {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  DartSdk sdk;
  AnalysisContext context;
  static String secFile;
  static Store store;
  static ConstraintSet cs;
  static Map<String, IType> declaredStore;

  static void reset() {
    TRNIAnalyzer.store = new Store();
    TRNIAnalyzer.cs = new ConstraintSet();
    TRNIAnalyzer.declaredStore = new Map();
  }

  TRNIAnalyzer(String secFile) {
    TRNIAnalyzer.reset();
    TRNIAnalyzer.secFile = secFile;
    _setUpLogger();

    sdk = new FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(getSdkPath()));
    context = AnalysisEngine.instance.createAnalysisContext();

    final packageMap = <String, List<Folder>>{
      "TRNIdart": [resourceProvider.getFolder("/TRNIdart")]
    };
    final packageResolver =
    new PackageMapUriResolver(resourceProvider, packageMap);

    final sf = new SourceFactory([
      new DartUriResolver(sdk),
      packageResolver,
      new ResourceUriResolver(resourceProvider)
    ]);

    context.sourceFactory = sf;


  }

  void _setUpLogger() {
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
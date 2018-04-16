import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/analyzer.dart' show AnalysisError, CompilationUnit;
import 'dart:io' as io show File;
import 'package:path/path.dart' as pathos;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
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

class TRNIAnalyzer {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  DartSdk sdk;
  AnalysisContext context;

  TRNIAnalyzer() {
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

  static List<AnalysisError> computeErrors(CompilationUnit resolvedUnit) {
    ErrorCollector errorCollector = new ErrorCollector();
    resolvedUnit.accept(new LabelVisitor(errorCollector));
    return errorCollector.errors;
  }

}
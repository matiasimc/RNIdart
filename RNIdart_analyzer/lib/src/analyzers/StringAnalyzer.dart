import 'package:RNIdart_analyzer/RNIdart_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:cli_util/cli_util.dart' show getSdkPath;

class StringAnalyzer {

  String stringToAnalyze;
  CompilationUnit compilationUnit;
  String dartSDK = getSdkPath();

  StringAnalyzer(String code) {
    this.stringToAnalyze = code;

    PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    DartSdk sdk = new FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(dartSDK));

    var resolvers = [
      new DartUriResolver(sdk),
      new ResourceUriResolver(resourceProvider)
    ];


    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
      ..sourceFactory = new SourceFactory(resolvers);

    Source source = new StringSource(this.stringToAnalyze);
    ChangeSet changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);
    LibraryElement libElement = context.computeLibraryElement(source);
    CompilationUnit resolvedUnit =
    context.resolveCompilationUnit(source, libElement);

    this.compilationUnit = resolvedUnit;
  }

  void acceptForAll(AstVisitor visitor) {
    this.compilationUnit.accept(visitor);
  }

  String getCode() {
    return this.compilationUnit.toSource();
  }

}
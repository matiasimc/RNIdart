import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:cli_util/cli_util.dart' show getSdkPath;

class FileAnalyzer {

  List<String> filesToAnalyze;
  CompilationUnit resolvedUnit;
  String dartSDK = getSdkPath();
  List<CompilationUnit> compilationUnits;

  FileAnalyzer(List<String> filesToAnalyze) {
    this.filesToAnalyze = filesToAnalyze;
    this.compilationUnits = new List<CompilationUnit>();

    PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    DartSdk sdk = new FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(dartSDK));

    var resolvers = [
      new DartUriResolver(sdk),
      new ResourceUriResolver(resourceProvider)
    ];


    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
      ..sourceFactory = new SourceFactory(resolvers);
    

    for (String file in filesToAnalyze) {
      Source source = new FileSource(resourceProvider.getFile(file));
      ChangeSet changeSet = new ChangeSet()..addedSource(source);
      context.applyChanges(changeSet);
      LibraryElement libElement = context.computeLibraryElement(source);
      CompilationUnit resolvedUnit =
      context.resolveCompilationUnit(source, libElement);

      this.compilationUnits.add(resolvedUnit);
    }
  }

  void acceptForAll(AstVisitor visitor) {
    for (CompilationUnit c in this.compilationUnits) {
      c.accept(visitor);
    }
  }

  String getCode() {
    String ret = "";
    for (CompilationUnit c in this.compilationUnits) {
      ret += "${c.toSource()}";
    }
    return ret;
  }

}
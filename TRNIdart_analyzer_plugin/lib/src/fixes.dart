import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:TRNIdart_analyzer/analyzer.dart';
import 'package:TRNIdart_analyzer_plugin/plugin.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class TRNIFixContributor implements FixContributor {
  String path;
  String secFile;

  TRNIFixContributor(this.path, this.secFile);


  @override
  void computeFixes(TRNIFixesRequest request, FixCollector collector) {
    for (AnalysisError error in request.errorsToFix) {
      if (error is UndefinedFacetError) {
        IType t = TRNIAnalyzer.store.getType(error.e);
        if (t is ObjectType) {
          SourceChange change = new SourceChange("Create empty facet.");
          SourceFileEdit se = new SourceFileEdit(this.secFile, error.source.contents.modificationTime);
          String facet =
          '''
abstract class ${error.facetName} {
  
}
        ''';
          se.add(new SourceEdit(0, 0, facet));
          change.addFileEdit(se);
          collector.addFix(error, new PrioritizedSourceChange(100, change));
        }
      }
    }
  }
}
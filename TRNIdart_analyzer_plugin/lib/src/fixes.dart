import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:TRNIdart_analyzer_plugin/plugin.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class TRNIFixContributor implements FixContributor {
  String path;

  TRNIFixContributor(this.path);


  @override
  void computeFixes(TRNIFixesRequest request, FixCollector collector) {
    for (AnalysisError error in request.errorsToFix) {
      SourceChange change = new SourceChange("Add dummy interface");
      SourceFileEdit se = new SourceFileEdit(this.path, error.source.contents.modificationTime);
      se.add(new SourceEdit(error.offset, 0, "@declared(Top) "));
      //se.add(new SourceEdit(error.source.contents.data.length, 0, "abstract class DummyClass {}"));
      change.addFileEdit(se);
      collector.addFix(error, new PrioritizedSourceChange(100, change));
    }
  }
}
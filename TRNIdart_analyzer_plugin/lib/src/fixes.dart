import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:TRNIdart_analyzer_plugin/plugin.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/fixes/fix_contributor_mixin.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'dart:io';


class TRNIFixContributor implements FixContributor {
  String path;

  TRNIFixContributor(this.path);


  @override
  void computeFixes(TRNIFixesRequest request, FixCollector collector) {
    for (AnalysisError error in request.errorsToFix) {
      SourceChange change = new SourceChange("Add dummy interface");
      SourceFileEdit se = new SourceFileEdit(this.path, 1);
      se.add(new SourceEdit(error.offset, 0, "@interface(\"DummyClass\") "));
      change.addFileEdit(se);
      collector.addFix(error, new PrioritizedSourceChange(100, change));
    }
  }
}
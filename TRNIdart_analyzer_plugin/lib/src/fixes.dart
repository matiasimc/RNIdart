import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/fixes/fix_contributor_mixin.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'dart:io';


class TRNIFixContributor extends Object with FixContributorMixin implements FixContributor {

  static FixKind kind = new FixKind('dummyAdd', 100, "Message test");
  AnalysisSession get session => request.result.session;

  void _dummyAdd(AnalysisError error) {
    DartChangeBuilder builder = new DartChangeBuilder(session);
    builder.addFileEdit(error.source.uri.toFilePath(), (DartFileEditBuilder fileEditBuilder) {
      fileEditBuilder.addSimpleInsertion(error.offset, "@interface(\"DummyClass\")");
    });
    addFix(error, kind, builder);
  }

  @override
  void computeFixesForError(AnalysisError error) {
    _dummyAdd(error);
  }
}
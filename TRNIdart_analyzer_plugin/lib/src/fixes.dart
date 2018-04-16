import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/fixes/fix_contributor_mixin.dart';

class TRNIFixContributor extends Object with FixContributorMixin implements FixContributor {

  GlobalEnvironment env;

  TRNIFixContributor(this.env);

  @override
  void computeFixesForError(AnalysisError error) {
    // TODO: implement computeFixesForError
  }



}
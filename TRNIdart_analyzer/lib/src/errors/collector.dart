import 'package:analyzer/error/error.dart';

class ErrorCollector {
  List<AnalysisError> errors;

  ErrorCollector() {
   this.errors = new List<AnalysisError>();
  }
}
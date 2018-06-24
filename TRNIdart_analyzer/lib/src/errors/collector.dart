import 'package:analyzer/error/error.dart';

class ErrorCollector {
  Set<AnalysisError> errors;

  ErrorCollector() {
   this.errors = new Set<AnalysisError>();
  }
}
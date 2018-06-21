import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/error/error.dart';
import 'package:front_end/src/base/source.dart';

class TypeError extends AnalysisError {
  TypeError(Source source, int offset, int length, Constraint c) :
      super(source, offset, length, new TypeErrorCode(c, "Please check your security policies")) {

  }
}

class TypeErrorCode implements ErrorCode {
  final String name = "Type error";
  String message;
  final String correction;
  Constraint constraint;

  TypeErrorCode(this.constraint, [String this.correction]) {
    this.message = "The subtyping relation ${constraint} is invalid.";
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;

  @override
  String get uniqueName => this.name;
}

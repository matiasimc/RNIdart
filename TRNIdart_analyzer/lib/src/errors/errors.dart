import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/error/error.dart';
import 'package:front_end/src/base/source.dart';

class SubtypingError extends AnalysisError {
  Constraint c;
  SubtypingError(this.c) :
      super(c.location.source, c.location.offset, c.location.length, new SubtypingErrorCode(c, "Please check your security policies"));

  @override
  bool operator ==(Object o) => o is SubtypingError && o.c == this.c;
}

class SubtypingErrorCode implements ErrorCode {
  final String name = "Type error";
  String message;
  final String correction;
  Constraint constraint;

  SubtypingErrorCode(this.constraint, [String this.correction]) {
    this.message = "The subtyping relation ${constraint} is invalid.";
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;

  @override
  String get uniqueName => this.name;
}

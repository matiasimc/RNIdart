import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/error/error.dart';
import 'package:front_end/src/base/source.dart';

class UndefinedInterfaceError extends AnalysisError {

  var inferredInterface;

  UndefinedInterfaceError(Source source, int offset, int length, this.inferredInterface, String name) :
        super(source, offset, length, new UndefinedInterface(name, "Please define the security interface")) {
  }
}

class SecurityViolationError extends AnalysisError {

  SecurityViolationError(Source source, int offset, int length, ErrorCode errorCode) :
        super(source, offset, length, errorCode);

}

class UndefinedInterface implements ErrorCode {
  final String name = "Undefined interface";
  String message;
  final String correction;

  UndefinedInterface(String element, [String this.correction]) {
    this.message = "Undefined security policy for element ${element}";
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;

  @override
  String get uniqueName => this.name;
}

class DummyError implements ErrorCode {
  final String name = "Dummy Error";
  final String message = "This plugin works!";
  final String correction;

  DummyError([String this.correction]);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;

  @override
  String get uniqueName => this.name;
}
import 'package:analyzer/error/error.dart';

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
  ErrorType get type => ErrorType.STATIC_WARNING;

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
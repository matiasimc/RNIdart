import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/error/error.dart';

class SubtypingError extends AnalysisError {
  Constraint c;
  SubtypingError(this.c) :
      super(c.location.source, c.location.offset, c.location.length, new SubtypingErrorCode(c, "Please check your security policies"));

  @override
  bool operator ==(Object o) => o is SubtypingError && o.c == this.c;
}

class InferredFacetInfo extends AnalysisError {
  Element e;
  ObjectType facetType;
  InferredFacetInfo(this.e, this.facetType) : super(e.source, e.nameOffset, e.nameLength, new InferredFacetErrorCode(facetType));
}

class UnableToResolveError extends AnalysisError {
  Element e;
  UnableToResolveError(this.e) : super(e.source, e.nameOffset, e.nameLength, new UnableToResolveErrorCode("Please provide facet declarations to help the inference algorithm."));

}

class UnableToResolveErrorCode implements ErrorCode {
  final String name = "Unresolved facet";
  String message;
  final String correction;

  UnableToResolveErrorCode([this.correction]) {
    this.message = "The inference could not resolve the type for this element.";
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;

  @override
  String get uniqueName => this.name;
}

class InferredFacetErrorCode implements ErrorCode {
  final String name = "Facet info";
  String message;
  final String correction;
  ObjectType facetType;

  InferredFacetErrorCode(this.facetType, [String this.correction]) {
    this.message = "The inferred facet is: ${facetType}";
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.HINT;

  @override
  String get uniqueName => this.name;
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

import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';


class SubtypingError extends AnalysisError {
  Constraint c;
  ErrorLocation l;
  SubtypingError(this.c, this.l) :
      super(l.source, l.offset, l.length, new SubtypingErrorCode(c, l, "Please check your security policies"));

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

class UndefinedFacetError extends AnalysisError {
  AstNode e;
  String facetName;
  Source source;

  UndefinedFacetError(this.e, this.facetName, this.source) : super(source, e.offset, e.length, new UndefinedFacetErrorCode(facetName, "Please create the abstract class."));

}

class UndefinedFacetErrorCode implements ErrorCode {
  final String name = "Undefined facet";
  String message;
  final String correction;

  UndefinedFacetErrorCode(facetName, [this.correction]) {
    this.message = "The declared facet ${facetName} is not defined.";
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;

  @override
  String get uniqueName => this.name;
}

class UnableToResolveErrorCode implements ErrorCode {
  final String name = "Unresolved facet";
  String message;
  final String correction;

  UnableToResolveErrorCode([this.correction]) {
    this.message = "Any declassification facet make the program well typed.";
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

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
    this.message = "The inferred declassification facet is: ${facetType}";
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
  ErrorLocation l;

  SubtypingErrorCode(this.constraint, this.l, [String this.correction]) {
    AstNode node = l.node;
    this.message = "Information flow error.";
    if (node is MethodInvocation) {
      this.message = "Information flow error in argument. Expected a subtype of ${constraint.right.cleanPrint()}. Found ${constraint.left.cleanPrint()}.";
    }
    if (node is ReturnStatement) {
      this.message = "Information flow error in the return statement. Expected a subtype of ${constraint.right.cleanPrint()}. Found ${constraint.left.cleanPrint()}.";
    }
    if (node is AssignmentExpression) {
      this.message = "Information flow error in the assignment. Expected a subtype of ${constraint.right.cleanPrint()}. Found ${constraint.left.cleanPrint()}.";
    }
  }

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;

  @override
  String get uniqueName => this.name;
}

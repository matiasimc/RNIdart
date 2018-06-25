import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';

class ErrorLocation {
  AstNode node;
  Source source;
  int length;
  int offset;

  ErrorLocation(this.source, this.length, this.offset, this.node);
}
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';

class ErrorLocation {
  AstNode node;
  Source source;
  int length;
  int offset;

  ErrorLocation(this.source, this.length, this.offset, this.node);

  @override
  bool operator ==(Object o) => o is ErrorLocation && source == o.source && length == o.length && offset == o.offset;

  @override
  int get hashCode => source.hashCode+length+offset;
}
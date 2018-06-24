import 'package:analyzer/src/generated/source.dart';

class ErrorLocation {
  Source source;
  int length;
  int offset;

  ErrorLocation(this.source, this.length, this.offset);
}
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/base/timestamped_data.dart';

class StringSource implements Source {

  String content;


  StringSource(String source) {
    this.content = source;
  }

  // TODO: implement contents
  @override
  TimestampedData<String> get contents {
    return new TimestampedData(0, this.content);
  }

  // TODO: implement encoding
  @override
  String get encoding => null;

  @override
  bool exists() {
    // TODO: implement exists
    return true;
  }

  // TODO: implement fullName
  @override
  String get fullName => "String based source";

  // TODO: implement isInSystemLibrary
  @override
  bool get isInSystemLibrary => false;

  // TODO: implement librarySource
  @override
  Source get librarySource => null;

  // TODO: implement modificationStamp
  @override
  int get modificationStamp => 0;

  // TODO: implement shortName
  @override
  String get shortName => "source";

  // TODO: implement source
  @override
  Source get source => this;

  // TODO: implement uri
  @override
  Uri get uri => null;

  // TODO: implement uriKind
  @override
  UriKind get uriKind => null;
}
import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';

abstract class NotificationManager {
  void recordAnalysisErrors(
      String path, LineInfo lineInfo, List<AnalysisError> analysisErrors);
}

/*
I used raimilcruz/secdart repo as a guide to implement this and other classes
 */
class TRNIDriver implements AnalysisDriverGeneric {
  final NotificationManager notificationManager;
  final AnalysisDriverScheduler _scheduler;
  final AnalysisDriver dartDriver;
  SourceFactory _sourceFactory;
  final FileContentOverlay _contentOverlay;

  final _addedFiles = new LinkedHashSet<String>();
  final _dartFiles = new LinkedHashSet<String>();
  final _changedFiles = new LinkedHashSet<String>();
  final _filesToAnalyze = new HashSet<String>();
  final _requestedDartFiles = new Map<String, List<Completer>>();

  TRNIDriver(this.notificationManager, this.dartDriver, this._scheduler,
      SourceFactory sourceFactory, this._contentOverlay) {
    _sourceFactory = sourceFactory.clone();
    _scheduler.add(this);
  }

  @override
  void addFile(String path) {
    _addedFiles.add(path);
    _dartFiles.add(path);
    fileChanged(path);
  }

  void fileChanged(String path) {
    if (_ownsFile(path)) {
      _changedFiles.add(path);
    }
    _scheduler.notify(this);
  }

  bool _ownsFile(String path) {
    return path.endsWith('.dart');
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  bool get hasFilesToAnalyze => _filesToAnalyze.isNotEmpty;

  @override
  Future<dynamic> performWork() async {
    if (_requestedDartFiles.isNotEmpty) {
      final path = _requestedDartFiles.keys.first;
      final completers = _requestedDartFiles.remove(path);
      // Note: We can't use await here, or the dart analysis becomes a future in
      // a queue that won't be completed until the scheduler schedules the dart
      // driver, which doesn't happen because its waiting for us.
      //resolveDart(path).then((result) {
      _resolveTRNIDart(path).then((result) {
        completers
            .forEach((completer) => completer.complete(result?.errors ?? []));
      }, onError: (e) {
        completers.forEach((completer) => completer.completeError(e));
      });
      return;
    }
    if (_changedFiles.isNotEmpty) {
      _changedFiles.clear();
      _filesToAnalyze.addAll(_dartFiles);
      return;
    }
    if (_filesToAnalyze.isNotEmpty) {
      final path = _filesToAnalyze.first;
      pushDartErrors(path);
      _filesToAnalyze.remove(path);
      return;
    }
    return;
  }

  //public api
  Future<List<AnalysisError>> requestDartErrors(String path) {
    var completer = new Completer<List<AnalysisError>>();
    _requestedDartFiles
        .putIfAbsent(path, () => <Completer<List<AnalysisError>>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  Future<TRNIResult> _resolveTRNIDart(String path) async {
    final unit = await dartDriver.getUnitElement(path);
    final result = await dartDriver.getResult(path);
    if (unit.element == null) return null;

    //TODO: Filter error in a better way...
    if (result.errors != null) {
      var realErrors = result.errors
          .where((e) => e.errorCode.errorSeverity == ErrorSeverity.ERROR)
          .toList();
      if (realErrors.length != 0) {
        return new TRNIResult(realErrors);
      }
    }

    final unitAst = unit.element.computeNode();

    // TODO integrate with host package, for now only shows "hello world" error
    List<AnalysisError> errors = new List();
    errors.add(new AnalysisError(unitAst.element.librarySource, 0, 10,
        new StaticError("Hello world", "This plugin works!")));
    return new TRNIResult(errors);
  }

  Future pushDartErrors(String path) async {
    final result = await _resolveTRNIDart(path);
    if (result == null) return;
    final errors = new List<AnalysisError>.from(result.errors);
    final lineInfo = new LineInfo.fromContent(getFileContent(path));
    notificationManager.recordAnalysisErrors(path, lineInfo, errors);
  }

  String getFileContent(String path) {
    return _contentOverlay[path] ??
        ((source) =>
        source.exists() ? source.contents.data : "")(getSource(path));
  }

  Source getSource(String path) =>
      _sourceFactory.resolveUri(null, 'file:' + path);

  @override
  set priorityFiles(List<String> priorityPaths) {
    // TODO: implement priorityFiles
  }

  @override
  AnalysisDriverPriority get workPriority => AnalysisDriverPriority.general;
}

class TRNIResult {
  List<AnalysisError> errors;
  TRNIResult(this.errors);
}

class StaticError implements ErrorCode {
  final String name;
  final String message;
  final String correction;

  StaticError(String this.name, String this.message, [String this.correction]);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;

  @override
  String get uniqueName => this.name;
}
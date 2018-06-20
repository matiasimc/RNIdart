import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:TRNIdart_analyzer/analyzer.dart';

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
  }

  @override
  bool get hasFilesToAnalyze => _filesToAnalyze.isNotEmpty;

  @override
  Future<Null> performWork() async {
    TRNIAnalyzer.reset();
    if (_changedFiles.isNotEmpty) {
      _changedFiles.clear();
      _filesToAnalyze.addAll(_dartFiles);
      return;
    }
    if (_filesToAnalyze.isNotEmpty) {
      generateAndThenSolveConstraints();
      return;
    }
    return;
  }

  void generateAndThenSolveConstraints() async {
    for (final path in _addedFiles) {
      await pushDartErrors(path);
      await _filesToAnalyze.removeWhere((s) => s == path);
    }
    await TRNIAnalyzer.computeTypes();
  }

  Future<TRNIResult> resolveTRNIDart(String path) async {
    if (!_ownsFile(path)) return new TRNIResult(new List());
    final unit = await dartDriver.getUnitElement(path);
    if (unit.element == null) return null;

    final unitAst = unit.element.computeNode();
    return new TRNIResult(TRNIAnalyzer.computeErrors(unitAst));
  }

  Future pushDartErrors(String path) async {
    final result = await resolveTRNIDart(path);
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
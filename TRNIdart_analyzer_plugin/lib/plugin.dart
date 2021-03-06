import 'dart:async';

import 'package:TRNIdart_analyzer/analyzer.dart';
import 'package:TRNIdart_analyzer_plugin/src/fixes.dart';
import 'package:analyzer/context/context_root.dart' as analyzer;
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:TRNIdart_analyzer_plugin/src/TRNIdriver.dart';
import 'package:analyzer_plugin/plugin/fix_mixin.dart';
import 'dart:io';

/*
I used raimilcruz/secdart repo as a guide to implement this and other classes
 */
class TRNIDartPlugin extends ServerPlugin with FixesMixin {
  ContextRoot root;
  TRNIDartPlugin(ResourceProvider provider) : super(provider);


  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'Type-based Relaxed Noninterference plugin';

  @override
  String get version => '0.0.1';

  @override
  bool isCompatibleWith(Version serverVersion) => true;

  @override
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) {
    this.root = contextRoot;
    final root = new analyzer.ContextRoot(contextRoot.root, contextRoot.exclude)
      ..optionsFilePath = contextRoot.optionsFile;

    TRNIAnalyzer.setUpLogger();
    String secDartFile = _createSecFile(contextRoot.root);
    TRNIAnalyzer.secDartFile = secDartFile;

    final logger = new PerformanceLog(new StringBuffer());
    final builder = new ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = analysisDriverScheduler
      ..byteStore = byteStore
      ..performanceLog = logger
      ..fileContentOverlay = fileContentOverlay;
    final dartDriver = builder.buildDriver(root);

    final sourceFactory = dartDriver.sourceFactory;

    final driver = new TRNIDriver(new ChannelNotificationManager(channel),
      dartDriver,
      analysisDriverScheduler,
      sourceFactory,
      fileContentOverlay,
      secDartFile);
    return driver;
  }

  String _createSecFile(String root) {
    File facets = new File(root+"/sec.dart");
    String contentsFacets =
'''
import 'package:TRNIdart/TRNIdart.dart';
/*
File generated by TRNI analyzer plugin.

You can add new public facets here, like this:

abstract class StringToString {
  String toString();
}
*/
''';
    if (!facets.existsSync()) {
      facets.createSync(recursive: true);
      facets.writeAsStringSync(contentsFacets);
    }
    return root+"/sec.dart";
  }

  @override
  void contentChanged(String path) {
    final driver = TRNIDriverForPath(path);
    if (driver == null) {
      return;
    }
    driver.addFile(path);

    driver.dartDriver.addFile(path);
  }

  TRNIDriver TRNIDriverForPath(String path) {
    final driver = super.driverForPath(path);
    if (driver is TRNIDriver) {
      return driver;
    }
    return null;
  }

  @override
  List<FixContributor> getFixContributors(String path) {
    return <FixContributor>[new TRNIFixContributor(path, this.root.root+"/sec.dart")];
  }

  @override
  Future<FixesRequest> getFixesRequest(EditGetFixesParams parameters) async {
    final TRNIDriver driver = TRNIDriverForPath(parameters.file);
    if (driver != null) {
      TRNIResult result = await driver.resolveTRNIDart(parameters.file);
      return new TRNIFixesRequest(resourceProvider, parameters.offset, parameters.file, result.errors.toList());
    }
    return null;
  }


}

class TRNIFixesRequest extends FixesRequest {
  ResourceProvider resourceProvider;
  int offset;
  String path;
  List<AnalysisError> errorsToFix;
  AnalysisSession session;

  TRNIFixesRequest(this.resourceProvider, this.offset, this.path, this.errorsToFix);

}


class ChannelNotificationManager implements NotificationManager {
  final PluginCommunicationChannel channel;

  ChannelNotificationManager(this.channel);

  @override
  void recordAnalysisErrors(
      String path, LineInfo lineInfo, List<AnalysisError> analysisErrors) {
    final converter = new AnalyzerConverter();
    final errors = converter.convertAnalysisErrors(
        analysisErrors,
        lineInfo: lineInfo,
    );
    channel.sendNotification(
        new plugin.AnalysisErrorsParams(path, errors).toNotification());
    }
}
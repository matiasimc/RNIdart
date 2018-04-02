/*
This class do the inference, given a GlobalEnvironment
 */
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class Inference {
  final Logger log = new Logger("Inference");
  List<AbstractClass> abstractClasses;
  GlobalEnvironment env;
  int abstractClassCount;
  NodeGenerator nodeGenerator;

  Inference(GlobalEnvironment env) {
    this.abstractClasses = new List<AbstractClass>();
    this.env = env;
    this.abstractClassCount = 0;
    this.nodeGenerator = new NodeGenerator();
  }

  doInference() {
    log.shout("Doing inference...");
    for (ClassElement c in env.classes.values) {
      // TODO infer the type interface of class members
    }

    for (VariableDeclaration v in env.variables.values) {
      // TODO infer the type interface of global variables
    }

    for (FunctionElement f in env.functions.values) {
      log.shout("Generating functions...");
      f.parameterUsage.forEach(
          (node, usage) {
            String abstractClassName = "${node.element.type}_${++this.abstractClassCount}";
            AbstractClass ac = new AbstractClass(abstractClassName);
            for (MethodInvocation m in usage.methodCalls) {
              ac.addMember(m.staticInvokeType.element.computeNode().toString());
            }
            for (PrefixedIdentifier f in usage.fieldCalls) {
              ac.addMember("${f.bestType} get ${f.endToken};");
            }
            this.addAbstractClass(ac);
            FormalParameter newNode = this.nodeGenerator.generateParameter(node, abstractClassName);
            node.parent.accept(new NodeReplacer(node, newNode));
          }
      );
    }
    for (LocalEnvironment l in env.localEnvs) {
      l.chainedCalls.forEach(
          (node, usage) {
            // TODO generate the abstract class for chained calls
          }
      );
      l.variables.forEach(
          (node, usage) {
            // TODO generate the abstract class and add the type annotation for local variables
          }
      );
    }
  }

  addAbstractClass(AbstractClass ac) {
    log.shout("Added abstract class ${ac.name}");
    this.abstractClasses.add(ac);
  }

  String getAbstractClassesSource() {
    String ret = "";
    this.abstractClasses.forEach((ac) => ret+=ac.getSource()+'\n');
    return ret;
  }
}
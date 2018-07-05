import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class Store {
  /*
  Map relating a variable to a virtual memory location
   */
  Map<Element, int> elements;

  /*
  Map relating a virtual memory location to a type
   */
  Map<int, IType> types;

  /*
  Map of expressions
   */
  Map<Expression, IType> expressions;

  int storeIndex, varIndex;

  Store() {
    this.elements = new Map();
    this.types = new Map();
    this.expressions = new Map();
    this.storeIndex = 0;
    this.varIndex = 0;
  }

  void addElement(Element v, {IType declaredType}) {
    if (!this.elements.containsKey(v)) elements[v] = this.storeIndex++;
    if (declaredType != null) {
      types[elements[v]] = declaredType;
    }
    else {
      types[elements[v]] = new TVar(varIndex++);
    }
  }

  TVar getTypeVariable() {
    return new TVar(varIndex++);
  }

  bool hasElement(Element e) {
    return this.elements.containsKey(e);
  }

  IType getType(Element e) {
    return types[elements[e]];
  }

  SchrodingerType getSchrodingerType(IType nonTop) {
    return new SchrodingerType(nonTop, varIndex++);
  }

  IType getTypeOrVariable(Element e) {
    if (e == null) return this.getTypeVariable();
    if (!this.hasElement(e)) this.addElement(e);
    return getType(e);
  }

  String printStore() {
    String ret = "";
    this.elements.forEach((e,i) {
      ret += "${e.toString()} -> $i\n";
    });
    ret += "\n";
    this.types.forEach((i,t) {
      ret += "$i -> $t\n";
    });

    return ret;
  }
}
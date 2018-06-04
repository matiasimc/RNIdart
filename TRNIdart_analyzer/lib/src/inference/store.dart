import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';

class Store {
  /*
  Map relating a variable to a virtual memory location
   */
  Map<String, int> variables;

  /*
  Map relating a virtual memory location to a type
   */
  Map<int, IType> types;

  int storeIndex, varIndex;

  Store() {
    this.variables = new Map<String, int>();
    this.types = new Map<int, IType>();
    this.storeIndex = 0;
    this.varIndex = 0;
  }

  void addVariable(String v, [IType declaredType]) {
    if (!this.variables.containsKey(v)) variables[v] = this.storeIndex++;
    if (declaredType != null) {
      types[variables[v]] = declaredType;
    }
    else {
      types[variables[v]] = new TVar(varIndex++);
    }
  }

  ObjectType addObjectTypeVariable(String v) {
    ObjectType t = new ObjectType();
    variables[v] = this.storeIndex++;
    types[variables[v]] = t;
    return t;
  }

  TVar getTypeVariable() {
    return new TVar(varIndex++);
  }
}
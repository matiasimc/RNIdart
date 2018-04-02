class AbstractClass {
  String name;
  List<String> members;

  AbstractClass(String name) {
    this.name = name;
    this.members = new List<String>();
  }

  addMember(String m) {
    this.members.add(m);
  }

  String getSource() {
    String mem = "";
    this.members.forEach((m) => mem+='\n\t'+m);
    return "abstract class ${this.name} {${mem}\n}";
  }
}
import 'package:test/test.dart';
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'test_helpers.dart';

void main() {
  MemoryFileTest mft;
  setUp(() {
    mft = new MemoryFileTest();
    mft.setUp();
  });
  test("Basic inference of method usage", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    class Bar {
      void bar(String s) {
        s.toLowerCase();
      }
    }
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "String s");
    var members = new Map();
    members["toLowerCase"] = new ArrowType([], new Bot());
    var expected = new ObjectType(members);
    expect(result, equals(expected));
  });

  test("Test of declared facet", () {
    var program =
        '''
        import "package:TRNIdart/TRNIdart.dart";
        
        abstract class StringToString {
          String toString();
        }
        
        class Foo {
          String bar(@S("StringToString") String s) {
            return s;
          }
        }
        
        ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "bar(String s) → String");
    var members = new Map(); members["toString"] = new ArrowType([], new Bot());
    expect(result, equals(new ObjectType(members)));
  });

  test("Test of chained method call", () {
    var program =
        '''
        import "package:TRNIdart/TRNIdart.dart";
        
        class Foo {
          void foo(String s) {
            s.toLowerCase().toString().substring(0);
          }
        }
        ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "String s");
    var members3 = new Map(); members3["substring"] = new ArrowType([new Bot()], new Bot());
    var members2 = new Map(); members2["toString"] = new ArrowType([], new ObjectType(members3));
    var members = new Map(); members["toLowerCase"] = new ArrowType([], new ObjectType(members2));
    expect(result, equals(new ObjectType(members)));
  });

  test("Test of chained method calls combined with another method call", () {
    var program =
        '''
        import "package:TRNIdart/TRNIdart.dart";
        
        abstract class StringToString {
            @S("Bot") String toString();
        }
        
        class C1 {
          C2 m(C2 c) {
            c.m4();
            return c.m1().m2().m3();
          }
        }
        
        class C2 {
          C2 m1() {
            return this;
          }
        
          C2 m2() {
            return this;
          }
        
          @S("Bot") C2 m3() {
            return this;
          }
        
          @S("StringToString") String m4() {
            return "hola";
          }
        }
        
        
        ''';
    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "C2 c");
    var members4 = new Map(); members4["toString"] = new ArrowType([], new Bot());
    var members3 = new Map(); members3["m3"] = new ArrowType([], new Bot());
    var members2 = new Map(); members2["m2"] = new ArrowType([], new ObjectType(members3));
    var members = new Map(); members["m1"] = new ArrowType([], new ObjectType(members2));
    members["m4"] = new ArrowType([], new ObjectType(members4));
    expect(result, equals(new ObjectType(members)));
  });

  test("Test of parameters join and return", () {
    var program =
        '''
        class C1 {
          void foo(C2 c21) {
            c21.m1();
          }
        
          void bar(C2 c22) {
            c22.m2();
          }
        }
        
        class C2 {
          void baz(C1 c1, C2 c23) {
            c1.foo(c23);
            c1.bar(c23);
          }
        
          void m1() {
        
          }
        
          void m2() {
        
          }
        }
        ''';
    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "C2 c23");
    var members = new Map(); members["m1"] = new ArrowType([], new Bot());
    members["m2"] = new ArrowType([], new Bot());
    expect(result, equals(new ObjectType(members)));
  });
}
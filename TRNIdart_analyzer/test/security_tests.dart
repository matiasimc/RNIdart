import 'package:test/test.dart';
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'test_helpers.dart';

void main() {
  MemoryFileTest mft;
  setUp(() {
    mft = new MemoryFileTest();
    mft.setUp();
  });
  test("Default facet for core dart method should be ${CORE_PARAMETER_FACET} -> ${CORE_RETURN_FACET}", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    class LoginScreen {
      int login(String password, String guess){
        return password.compareTo(guess);
      }
    }
    ''';

    var source = mft.newSource("/test.dart", program);
    var result1 = mft.checkTypeForSourceWithQuery(source, "String password");
    var result2 = mft.checkTypeForSourceWithQuery(source, "String guess");
    var result3 = mft.checkTypeForSourceWithQuery(source, "login(String password, String guess) → int");
    var members = new Map();
    members["compareTo"] = new ArrowType([CORE_PARAMETER_FACET], CORE_RETURN_FACET);
    var expected = new ObjectType(members);
    expect(result1, equals(expected));
    expect(result2, equals(CORE_PARAMETER_FACET));
    expect(result3, equals(CORE_RETURN_FACET));
  });

  test("Declared facet for core dart method should be ${CORE_PARAMETER_FACET} -> ${CORE_RETURN_FACET}", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    abstract class StringCompareTo {
      int compareTo(String other);
    }
    
    class LoginScreen {
      int login(String guess, @S("StringCompareTo") String password){
        return password.compareTo(guess);
      }
    }
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "login(String guess, String password) → int");
    expect(result, equals(CORE_RETURN_FACET));
  });

  test("Return of a method invocation that does not belong to the facet should be Top", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    abstract class StringCompareTo {
      int compareTo(String other);
    }
    
    class LoginScreen {
      int login(String guess, @S("Top") String password){
        return password.compareTo(guess);
      }
    }
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "login(String guess, String password) → int");
    expect(result, equals(new Top()));
  });

  test("Test of declared facet in a method of another facet", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    abstract class IntCompareTo {
      int compareTo(num other);
    }
    
    abstract class StringHashCompareTo {
      @S("IntCompareTo") int get hashCode;
    }
    
    class LoginScreen {
      int login(int passwordHash, @S("StringHashCompareTo") String password) {
        return password.hashCode.compareTo(passwordHash);
      }
    }
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "login(int passwordHash, String password) → int");
    expect(result, equals(new Bot()));
  });

  test("Test of declared facet in a method of another facet that evaluates to Top", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    abstract class IntCompareTo {
      int compareTo(num other);
    }
    
    abstract class StringHashCompareTo {
      @S("IntCompareTo") int get hashCode;
    }
    
    class LoginScreen {
      int login(int passwordHash, @S("StringHashCompareTo") String password) {
        return password.hashCode.toString();
      }
    }
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "login(int passwordHash, String password) → int");
    expect(result, equals(new Top()));
  });

  test("Using a method invocation that returns Top as an argument when the method declared Bot in the parameter should be an error", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    class LoginScreen {
      void login(@S("Top") String password) {
        check(password.toLowerCase());
      }
      
      String check(@S("Bot") String password) {
        return password.substring(0);
      }
    }
    
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.hasSecurityError(source, "check(password.toLowerCase())");
    expect(result, isTrue);
  });

  test("The assignment should be affected by the conditional because of the PC", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    class Person {
      bool get permission => true;
    }
    
    class Foo {
      String foo(@S("Top") Person p){
        String ret = "denegado";
        if (p.permission) {
          ret = "exito";
        }
        return ret;
      }
    }
    
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.checkTypeForSourceWithQuery(source, "foo(Person p) → String");
    expect(result, equals(new Top()));
  });

  test("The assignment should throw an error if declared a facet that is not supertype of the PC", () {
    var program =
    '''
    import "package:TRNIdart/TRNIdart.dart";
    
    abstract class StringToString {
      String toString();
    }
    
    abstract class StringToStringAndToLowerCase {
      String toString();
      String toLowerCase();
    }
    
    class Person {
      @S("StringToString") bool get permission => true;
    }
    
    class Foo {
      String foo(Person p){
        @S("StringToStringAndToLowerCase") String ret = "denegado";
        while (p.permission) {
          ret = "exito";
        }
        return ret;
      }
    }
    
    ''';

    var source = mft.newSource("/test.dart", program);
    var result = mft.hasSecurityError(source, "ret = \"exito\"");
    expect(result, isTrue);
  });

}
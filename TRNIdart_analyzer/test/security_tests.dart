import 'package:test/test.dart';
import 'package:TRNIdart_analyzer/TRNIdart_analyzer.dart';
import 'test_helpers.dart';

void main() {
  MemoryFileTest mft;
  setUp(() {
    mft = new MemoryFileTest();
    mft.setUp();
  });
  test("Default facet for core dart method should be Bot -> Bot", () {
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
    members["compareTo"] = new ArrowType([new Bot()], new Bot());
    var expected = new ObjectType(members);
    expect(result1, equals(expected));
    expect(result2, equals(new Bot()));
    expect(result3, equals(new Bot()));
  });

  test("Declared facet for core dart method test should be Bot -> Bot", () {
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
    expect(result, equals(new Bot()));
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

}
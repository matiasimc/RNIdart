# Type-based declassification inference for Dart

## How to use

Add the following dependency to `pubspec.yaml`:

```
dependencies:
  TRNIdart:
    git:
      url: git://github.com/matiasimc/TRNIdart
      path: TRNIdart/
```

Then add the plugin to the `analysis_options.yaml` file in the project root. Create it if it does not exists.

```
analyzer:
  strong-mode: true
  plugins:
      - TRNIdart
```

Then, do a `pub get` and restart the analysis server. It should take 10 to 20 seconds to load the plugin. Make sure to refresh the project 
structure after the plugin is loaded, because a file `sec.dart` should be created in the project root.

Finally, add the following import statement to your sources:

```
import 'package:TRNIdart/TRNIdart.dart';
```

Note: tested in Dart version 2.0.0-dev.60.0

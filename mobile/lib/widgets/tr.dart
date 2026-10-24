import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

extension Tr on BuildContext {
  /// The app's own English text in the chosen language. Use inside build methods.
  String tr(String english) => watch<AppState>().t(english);

  /// Same, for callbacks outside build (snack bars, dialogs).
  String trNow(String english) => read<AppState>().t(english);
}

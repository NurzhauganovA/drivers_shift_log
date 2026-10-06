import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shift_log/src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ru';
  await initializeDateFormatting('ru');
  runApp(
    // Failed requests surface as an error state with a retry button,
    // so automatic provider retries are turned off.
    ProviderScope(retry: (_, _) => null, child: const ShiftLogApp()),
  );
}

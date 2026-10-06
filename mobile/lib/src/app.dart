import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shift_log/src/core/theme/app_theme.dart';
import 'package:shift_log/src/features/shift/presentation/screens/shift_screen.dart';

class ShiftLogApp extends StatelessWidget {
  const ShiftLogApp({super.key});

  /// Keeps the layout phone-shaped on tablets and desktop browsers.
  static const maxContentWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дневник смен',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: child,
          ),
        ),
      ),
      home: const ShiftScreen(),
    );
  }
}

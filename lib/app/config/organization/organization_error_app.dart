import 'package:flutter/material.dart';

/// Shown instead of the app when the build has no usable organization, so the
/// cause is on screen and not only in a minified log.
class OrganizationErrorApp extends StatelessWidget {
  const OrganizationErrorApp({super.key, required this.message});

  /// Why the organization could not be loaded and how to fix the build.
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MonAmie',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

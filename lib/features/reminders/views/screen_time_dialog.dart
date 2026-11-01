import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The "you've been using your phone for a while" pop-up.
Future<void> showScreenTimeDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.visibility_off, color: AppColors.calories, size: 40),
      title: const Text('Time for a screen break'),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Remind me later')),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK, taking a break')),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../config/adyen_config.dart';
import '../models/adyen_session_result.dart';
import 'adyen_card_component.dart';

/// Modal bottom sheet hosting [AdyenCardComponent].
Future<AdyenSessionResult?> showAdyenCardDropIn(
  BuildContext context, {
  required AdyenConfig config,
  required String sessionId,
  required String sessionData,
  double heightFactor = 0.35,
}) {
  return showModalBottomSheet<AdyenSessionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * heightFactor;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: height,
            child: SafeArea(
              top: false,
              child: AdyenCardComponent(
                config: config,
                sessionId: sessionId,
                sessionData: sessionData,
                onFinished: (result) => Navigator.pop(sheetContext, result),
                onError: (message) {
                  Navigator.pop(
                    sheetContext,
                    AdyenSessionResult(
                      resultCode: 'Error',
                      raw: {'message': message},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

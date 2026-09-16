import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../adyen_checkout_channels.dart';
import '../config/adyen_config.dart';
import '../models/adyen_session_result.dart';

/// Embeddable native Adyen card component (Sessions + scheme).
class AdyenCardComponent extends StatefulWidget {
  const AdyenCardComponent({
    super.key,
    required this.config,
    required this.sessionId,
    required this.sessionData,
    this.onLoaded,
    this.onFinished,
    this.onError,
    this.onAction,
  });

  final AdyenConfig config;
  final String sessionId;
  final String sessionData;
  final VoidCallback? onLoaded;
  final ValueChanged<AdyenSessionResult>? onFinished;
  final ValueChanged<String>? onError;
  final ValueChanged<String>? onAction;

  @override
  State<AdyenCardComponent> createState() => _AdyenCardComponentState();
}

class _AdyenCardComponentState extends State<AdyenCardComponent> {
  MethodChannel? _channel;

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel(AdyenCheckoutChannels.cardViewEvents(id));
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onLoaded':
          widget.onLoaded?.call();
          break;
        case 'onFinished':
          final result = AdyenSessionResult.fromDynamic(call.arguments);
          widget.onFinished?.call(result);
          break;
        case 'onError':
          final message = _errorMessage(call.arguments);
          widget.onError?.call(message);
          break;
        case 'onAction':
          final type = call.arguments is Map
              ? (call.arguments as Map)['type']?.toString() ?? ''
              : call.arguments?.toString() ?? '';
          widget.onAction?.call(type);
          break;
      }
    });
  }

  String _errorMessage(dynamic args) {
    if (args is Map && args['message'] != null) {
      return args['message'].toString();
    }
    return args?.toString() ?? 'Unknown Adyen card error';
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.config.toCreationParams(
      sessionId: widget.sessionId,
      sessionData: widget.sessionData,
    );
    const codec = StandardMessageCodec();

    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    if (Platform.isIOS) {
      return UiKitView(
        viewType: AdyenCheckoutChannels.cardViewType,
        creationParams: params,
        creationParamsCodec: codec,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: AdyenCheckoutChannels.cardViewType,
        creationParams: params,
        creationParamsCodec: codec,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return const SizedBox.shrink();
  }
}

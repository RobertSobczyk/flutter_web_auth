import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show MethodChannel;

class _OnAppLifecycleResumeObserver extends WidgetsBindingObserver {
  final Function onResumed;

  _OnAppLifecycleResumeObserver(this.onResumed);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

class FlutterWebAuth {
  static const MethodChannel _channel = const MethodChannel('flutter_web_auth');

  static final _OnAppLifecycleResumeObserver _resumedObserver = _OnAppLifecycleResumeObserver(() {
    _cleanUpDanglingCalls(); // unawaited
  });

  /// Ask the user to authenticate to the specified web service.
  ///
  /// The page pointed to by [url] will be loaded and displayed to the user.
  /// From the page, the user can authenticate herself and grant access to the app.
  /// On completion, the service will send a callback URL with an authentication token,
  /// and this URL will be result of the returned [Future].
  ///
  /// [callbackUrlScheme] a string specifying the scheme of the url that the page will redirect to upon successful authentication.
  /// [showBrowserChooser] a boolean to always show a browser chooser to the user when he has multiple browser installed,
  /// can be usefull if some browser restriction rules are set by the authentication service).
  static Future<String> authenticate(
      {required String url,
      required String callbackUrlScheme,
      bool showBrowserChooser = false,
      bool? preferEphemeral}) async {
    WidgetsBinding.instance?.removeObserver(_resumedObserver); // safety measure so we never add this observer twice
    WidgetsBinding.instance?.addObserver(_resumedObserver);
    return await _channel.invokeMethod('authenticate', <String, dynamic>{
      'url': url,
      'callbackUrlScheme': callbackUrlScheme,
      'preferEphemeral': preferEphemeral ?? false,
      'showBrowserChooser': showBrowserChooser,
    }) as String;
  }

  /// On Android, the plugin has to store the Result callbacks in order to pass the result back to the caller of
  /// `authenticate`. But if that result never comes the callback will dangle around forever. This can be called to
  /// terminate all `authenticate` calls with an error.
  static Future<void> _cleanUpDanglingCalls() async {
    await _channel.invokeMethod('cleanUpDanglingCalls');
    WidgetsBinding.instance?.removeObserver(_resumedObserver);
  }
}

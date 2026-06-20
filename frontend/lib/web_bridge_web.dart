// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

StreamSubscription<html.Event> watchDocumentVisibility(
  void Function() onHidden,
) {
  return html.document.onVisibilityChange.listen((_) {
    if (html.document.hidden == true) {
      onHidden();
    }
  });
}

StreamSubscription<html.Event> watchNavigation(void Function() onNavigate) {
  return html.window.onPopState.listen((_) {
    onNavigate();
  });
}

void Function() mountHiddenIframe(String src) {
  final iframe = html.IFrameElement()
    ..style.border = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.position = 'absolute'
    ..style.left = '-9999px'
    ..src = src;
  html.document.body?.append(iframe);
  return iframe.remove;
}

void navigateTo(String path) {
  html.window.history.pushState(null, '', path);
}

void openExternalUrl(String url) {
  html.window.open(url, '_blank', 'noopener');
}

Future<bool> copyText(String text) async {
  try {
    await html.window.navigator.clipboard?.writeText(text);
    return true;
  } catch (_) {
    return false;
  }
}

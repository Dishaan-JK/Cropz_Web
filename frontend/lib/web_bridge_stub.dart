import 'dart:async';

StreamSubscription<void> watchDocumentVisibility(void Function() onHidden) {
  return const Stream<void>.empty().listen((_) {});
}

VoidCallback mountHiddenIframe(String src) {
  return () {};
}

void navigateTo(String path) {}

void openExternalUrl(String url) {}

Future<bool> copyText(String text) async => false;

typedef VoidCallback = void Function();

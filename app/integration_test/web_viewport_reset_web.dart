import 'dart:js_interop';

@JS('window.scrollTo')
external void _scrollTo(JSNumber x, JSNumber y);

void resetBrowserViewport() {
  _scrollTo(0.toJS, 0.toJS);
}

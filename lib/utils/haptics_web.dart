import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('navigator')
external JSObject get _navigator;

void _vibrate(int duration) {
  // Safari on iOS does not implement navigator.vibrate. Check before calling
  // it so an optional haptic effect cannot interrupt the user's tap action.
  if (_navigator.getProperty<JSAny?>('vibrate'.toJS) == null) return;
  _navigator.callMethod<JSAny?>('vibrate'.toJS, [duration.toJS]);
}

void lightImpact() => _vibrate(30);

void mediumImpact() => _vibrate(60);

void heavyImpact() => _vibrate(100);

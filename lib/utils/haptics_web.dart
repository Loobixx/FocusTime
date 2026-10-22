import 'dart:js_interop';

@JS('navigator.vibrate')
external JSBoolean _vibrate(JSAny pattern);

void lightImpact() => _vibrate(30.toJS);

void mediumImpact() => _vibrate(60.toJS);

void heavyImpact() => _vibrate(100.toJS);

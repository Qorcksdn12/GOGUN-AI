if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions) {
    _global.mx.transitions = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions.easing) {
    _global.mx.transitions.easing = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions.easing.Regular) {
    mx.transitions.easing.Regular = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.easeIn = function (t, b, c, d) {
        return c * (t = t / d) * t + b;
    };
    _r1.easeOut = function (t, b, c, d) {
        return (0 - c) * (t = t / d) * (t - 2) + b;
    };
    _r1.easeInOut = function (t, b, c, d) {
        if ((t = t / (d / 2)) < 1) {
            return c / 2 * t * t + b;
        }
        return (0 - c) / 2 * ((t = t - 1) * (t - 2) - 1) + b;
    };
    _r1.version = "1.1.0.52";
}
ASSetPropFlags(mx.transitions.easing.Regular.prototype, null, 1);
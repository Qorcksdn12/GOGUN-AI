if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions) {
    _global.mx.transitions = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions.OnEnterFrameBeacon) {
    mx.transitions.OnEnterFrameBeacon = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.init = function () {
        _r4 = _global.MovieClip;
        if (!_root.__OnEnterFrameBeacon) {
            mx.transitions.BroadcasterMX.initialize(_r4);
            _r3 = _root.createEmptyMovieClip("__OnEnterFrameBeacon", 9876);
            _r3.onEnterFrame = function () {
                _global.MovieClip.broadcastMessage("onEnterFrame");
            };
        }
    };
    _r1.version = "1.1.0.52";
}
ASSetPropFlags(mx.transitions.OnEnterFrameBeacon.prototype, null, 1);
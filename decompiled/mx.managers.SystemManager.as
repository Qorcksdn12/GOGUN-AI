if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers) {
    _global.mx.managers = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers.SystemManager) {
    mx.managers.SystemManager = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.init = function (Void) {
        if (mx.managers.SystemManager._initialized == false) {
            mx.managers.SystemManager._initialized = true;
            mx.events.EventDispatcher.initialize(mx.managers.SystemManager);
            Mouse.addListener(mx.managers.SystemManager);
            Stage.addListener(mx.managers.SystemManager);
            mx.managers.SystemManager._xAddEventListener = mx.managers.SystemManager.addEventListener;
            mx.managers.SystemManager.addEventListener = mx.managers.SystemManager.__addEventListener;
            mx.managers.SystemManager._xRemoveEventListener = mx.managers.SystemManager.removeEventListener;
            mx.managers.SystemManager.removeEventListener = mx.managers.SystemManager.__removeEventListener;
        }
    };
    _r1.addFocusManager = function (f) {
        mx.managers.SystemManager.form = f;
        f.focusManager.activate();
    };
    _r1.removeFocusManager = function (f) {
    };
    _r1.onMouseDown = function (Void) {
        _r1 = mx.managers.SystemManager.form;
        _r1.focusManager._onMouseDown();
    };
    _r1.onResize = function (Void) {
        _r7 = Stage.width;
        _r6 = Stage.height;
        _r9 = _global.origWidth;
        _r8 = _global.origHeight;
        _r3 = Stage.align;
        _r5 = (_r9 - _r7) / 2;
        _r4 = (_r8 - _r6) / 2;
        if (_r3 == "T") {
            _r4 = 0;
        } else {
            if (_r3 == "B") {
                _r4 = _r8 - _r6;
            } else {
                if (_r3 == "L") {
                    _r5 = 0;
                } else {
                    if (_r3 == "R") {
                        _r5 = _r9 - _r7;
                    } else {
                        if (_r3 == "LT") {
                            _r4 = 0;
                            _r5 = 0;
                        } else {
                            if (_r3 == "TR") {
                                _r4 = 0;
                                _r5 = _r9 - _r7;
                            } else {
                                if (_r3 == "LB") {
                                    _r4 = _r8 - _r6;
                                    _r5 = 0;
                                } else {
                                    if (_r3 == "RB") {
                                        _r4 = _r8 - _r6;
                                        _r5 = _r9 - _r7;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if (mx.managers.SystemManager.__screen == undefined) {
            mx.managers.SystemManager.__screen = new Object();
        }
        mx.managers.SystemManager.__screen.x = _r5;
        mx.managers.SystemManager.__screen.y = _r4;
        mx.managers.SystemManager.__screen.width = _r7;
        mx.managers.SystemManager.__screen.height = _r6;
        _root.focusManager.relocate();
        mx.managers.SystemManager.dispatchEvent({type: "resize"});
    };
    _r1.__get__screen = function () {
        mx.managers.SystemManager.init();
        if (mx.managers.SystemManager.__screen == undefined) {
            mx.managers.SystemManager.onResize();
        }
        return mx.managers.SystemManager.__screen;
    };
    _r1._initialized = false;
    _r1.idleFrames = 0;
    _r1.isMouseDown = false;
    _r1.forms = new Array();
}
ASSetPropFlags(mx.managers.SystemManager.prototype, null, 1);
/* leftover stack: ['_r1.addProperty("screen", _r1.__get__screen, function () {\n})'] */
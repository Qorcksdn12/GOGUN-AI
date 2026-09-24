if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers) {
    _global.mx.managers = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers.OverlappedWindows) {
    mx.managers.OverlappedWindows = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.checkIdle = function (Void) {
        if (mx.managers.SystemManager.idleFrames > 10) {
            mx.managers.SystemManager.dispatchEvent({type: "idle"});
        } else {
            mx.managers.SystemManager.idleFrames = mx.managers.SystemManager.idleFrames + 1;
        }
    };
    _r1.__addEventListener = function (e, o, l) {
        if (e == "idle") {
            if (mx.managers.SystemManager.interval == undefined) {
                mx.managers.SystemManager.interval = setInterval(mx.managers.SystemManager.checkIdle, 100);
            }
        }
        mx.managers.SystemManager._xAddEventListener(e, o, l);
    };
    _r1.__removeEventListener = function (e, o, l) {
        if (e == "idle") {
            if (mx.managers.SystemManager._xRemoveEventListener(e, o, l) == 0) {
                clearInterval(mx.managers.SystemManager.interval);
            }
        } else {
            mx.managers.SystemManager._xRemoveEventListener(e, o, l);
        }
    };
    _r1.onMouseDown = function (Void) {
        mx.managers.SystemManager.idleFrames = 0;
        mx.managers.SystemManager.isMouseDown = true;
        _r5 = _root;
        _r3 = undefined;
        _r8 = _root._xmouse;
        _r7 = _root._ymouse;
        if (mx.managers.SystemManager.form.modalWindow == undefined) {
            if (mx.managers.SystemManager.forms.length > 1) {
                _r6 = mx.managers.SystemManager.forms.length;
                _r4 = undefined;
                _r4 = 0;
                while (_r4 < _r6) {
                    _r2 = mx.managers.SystemManager.forms[_r4];
                    if (_r2._visible) {
                        if (_r2.hitTest(_r8, _r7)) {
                            if (_r3 == undefined) {
                                _r3 = _r2.getDepth();
                                _r5 = _r2;
                            } else {
                                if (_r3 < _r2.getDepth()) {
                                    _r3 = _r2.getDepth();
                                    _r5 = _r2;
                                }
                            }
                        }
                    }
                    _r4 = _r4 + 1;
                }
                if (_r5 != mx.managers.SystemManager.form) {
                    mx.managers.SystemManager.activate(_r5);
                }
            }
        }
        _r9 = mx.managers.SystemManager.form;
        _r9.focusManager._onMouseDown();
    };
    _r1.onMouseMove = function (Void) {
        mx.managers.SystemManager.idleFrames = 0;
    };
    _r1.onMouseUp = function (Void) {
        mx.managers.SystemManager.isMouseDown = false;
        mx.managers.SystemManager.idleFrames = 0;
    };
    _r1.activate = function (f) {
        if (mx.managers.SystemManager.form != undefined) {
            if (!(mx.managers.SystemManager.form == f) && mx.managers.SystemManager.forms.length > 1) {
                _r1 = mx.managers.SystemManager.form;
                _r1.focusManager.deactivate();
            }
        }
        mx.managers.SystemManager.form = f;
        f.focusManager.activate();
    };
    _r1.deactivate = function (f) {
        if (mx.managers.SystemManager.form != undefined) {
            if (mx.managers.SystemManager.form == f && mx.managers.SystemManager.forms.length > 1) {
                _r5 = mx.managers.SystemManager.form;
                _r5.focusManager.deactivate();
                _r3 = mx.managers.SystemManager.forms.length;
                _r1 = undefined;
                _r2 = undefined;
                _r1 = 0;
                while (_r1 < _r3) {
                    if (mx.managers.SystemManager.forms[_r1] == f) {
                        _r1 = _r1 + 1;
                        while (_r1 < _r3) {
                            if (mx.managers.SystemManager.forms[_r1]._visible == true) {
                                _r2 = mx.managers.SystemManager.forms[_r1];
                            }
                            _r1 = _r1 + 1;
                        }
                        mx.managers.SystemManager.form = _r2;
                        break;
                    } else {
                        if (mx.managers.SystemManager.forms[_r1]._visible == true) {
                            _r2 = mx.managers.SystemManager.forms[_r1];
                        }
                    }
                    _r1 = _r1 + 1;
                }
                _r5 = mx.managers.SystemManager.form;
                _r5.focusManager.activate();
            }
        }
    };
    _r1.addFocusManager = function (f) {
        mx.managers.SystemManager.forms.push(f);
        mx.managers.SystemManager.activate(f);
    };
    _r1.removeFocusManager = function (f) {
        _r3 = mx.managers.SystemManager.forms.length;
        _r1 = undefined;
        _r1 = 0;
        while (_r1 < _r3) {
            if (mx.managers.SystemManager.forms[_r1] == f) {
                if (mx.managers.SystemManager.form == f) {
                    mx.managers.SystemManager.deactivate(f);
                }
                mx.managers.SystemManager.forms.splice(_r1, 1);
                return undefined;
            }
            _r1 = _r1 + 1;
        }
    };
    _r1.enableOverlappedWindows = function () {
        if (!mx.managers.OverlappedWindows.initialized) {
            mx.managers.OverlappedWindows.initialized = true;
            mx.managers.SystemManager.checkIdle = mx.managers.OverlappedWindows.checkIdle;
            mx.managers.SystemManager.__addEventListener = mx.managers.OverlappedWindows.__addEventListener;
            mx.managers.SystemManager.__removeEventListener = mx.managers.OverlappedWindows.__removeEventListener;
            mx.managers.SystemManager.onMouseDown = mx.managers.OverlappedWindows.onMouseDown;
            mx.managers.SystemManager.onMouseMove = mx.managers.OverlappedWindows.onMouseMove;
            mx.managers.SystemManager.onMouseUp = mx.managers.OverlappedWindows.onMouseUp;
            mx.managers.SystemManager.activate = mx.managers.OverlappedWindows.activate;
            mx.managers.SystemManager.deactivate = mx.managers.OverlappedWindows.deactivate;
            mx.managers.SystemManager.addFocusManager = mx.managers.OverlappedWindows.addFocusManager;
            mx.managers.SystemManager.removeFocusManager = mx.managers.OverlappedWindows.removeFocusManager;
        }
    };
    _r1.initialized = false;
    _r1.SystemManagerDependency = mx.managers.SystemManager;
}
ASSetPropFlags(mx.managers.OverlappedWindows.prototype, null, 1);
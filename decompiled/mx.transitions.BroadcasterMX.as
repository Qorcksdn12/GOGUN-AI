if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions) {
    _global.mx.transitions = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions.BroadcasterMX) {
    mx.transitions.BroadcasterMX = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.initialize = function (o, dontCreateArray) {
        if (o.broadcastMessage != undefined) {
            delete o.broadcastMessage;
        }
        o.addListener = mx.transitions.BroadcasterMX.prototype.addListener;
        o.removeListener = mx.transitions.BroadcasterMX.prototype.removeListener;
        if (!dontCreateArray) {
            o._listeners = new Array();
        }
    };
    _r2.addListener = function (o) {
        this.removeListener(o);
        if (this.broadcastMessage == undefined) {
            this.broadcastMessage = mx.transitions.BroadcasterMX.prototype.broadcastMessage;
        }
        return this._listeners.push(o);
    };
    _r2.removeListener = function (o) {
        _r2 = this._listeners;
        _r3 = _r2.length;
        while (true) {
            _r3 = _r3 - 1;
            if (!_r3) break;
            if (_r2[_r3] == o) {
                _r2.splice(_r3, 1);
                if (!_r2.length) {
                    this.broadcastMessage = undefined;
                }
                return true;
            }
        }
        return false;
    };
    _r2.broadcastMessage = function () {
        _r5 = String(arguments.shift());
        _r4 = this._listeners.concat();
        _r6 = _r4.length;
        _r3 = 0;
        while (_r3 < _r6) {
            _r4[_r3][_r5].apply(_r4[_r3], arguments);
            _r3 = _r3 + 1;
        }
    };
    _r1.version = "1.1.0.52";
}
ASSetPropFlags(mx.transitions.BroadcasterMX.prototype, null, 1);
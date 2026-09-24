if (!_global.GlobalTarget) {
    _global.GlobalTarget = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.rootFind = function (target) {
        _r2 = [target];
        while (target = target._parent) {
            _r2.push(target);
        }
        return _r2;
    };
    _r1.getxy = function (target) {
        _r2 = GlobalTarget.rootFind(target);
        _r4 = 0;
        _r3 = 0;
        while ((_r0 = /*enum*/_r2) != null) {
            _r5 = _r0;
            _r1 = _r2[_r5];
            _r4 = _r4 + _r1._x;
            _r3 = _r3 + _r1._y;
        }
        return {_x: _r4, _y: _r3};
        /* leftover stack: ['null'] */
    };
    _r1.getdiv = function (t1, t2) {
        _r2 = GlobalTarget.getxy(t1);
        _r1 = GlobalTarget.getxy(t2);
        _r3 = Math.sqrt(Math.pow(_r1._x - _r2._x, 2) + Math.pow(_r1._y - _r2._y, 2));
        return _r3;
    };
    _r1.getdivxy = function (t1, t2, s) {
        _r2 = GlobalTarget.getxy(t1);
        _r1 = GlobalTarget.getxy(t2);
        return _r1[s] - _r2[s];
    };
    _r1.getsec = function (t1, t2) {
        _r2 = GlobalTarget.getxy(t1);
        _r1 = GlobalTarget.getxy(t2);
        return Math.atan2(_r1._y - _r2._y, _r1._x - _r2._x);
    };
    _r1.union = function (to, o) {
        _r2 = 0;
        while ((_r0 = /*enum*/o) != null) {
            _r4 = _r0;
            _r2 = _r2 + 1;
            to[_r4] = o[_r4];
        }
        return _r2;
        /* leftover stack: ['null'] */
    };
}
ASSetPropFlags(_global.GlobalTarget.prototype, null, 1);
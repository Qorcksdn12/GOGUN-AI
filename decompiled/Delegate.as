if (!_global.Delegate) {
    _global.Delegate = _r1 = function (fun) {
        super[undefined]();
        this.func = fun;
    };
    _global.Delegate.extends(Object);
    _r2 = _r1.prototype;
    _r1.create = function (obj, func) {
        _r2 = function () {
            _r2 = arguments.callee.target;
            _r3 = arguments.callee.func;
            _r4 = arguments.callee.args;
            return _r3.apply(_r2, _r4.concat(arguments));
        };
        _r2.target = arguments.shift();
        _r2.func = arguments.shift();
        _r2.args = arguments;
        return _r2;
    };
    _r2.createDelegate = function (obj) {
        return Delegate.create(obj, this.func);
    };
}
ASSetPropFlags(_global.Delegate.prototype, null, 1);
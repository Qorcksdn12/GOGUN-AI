if (!_global.MouseListener) {
    _global.MouseListener = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r2.onControl = function (bool) {
        this.use = bool;
        if (bool) {
            if (this.onMouseDown != undefined) {
                this.listener.onMouseDown = this.onMouseDown;
            }
            if (this.onMouseUp != undefined) {
                this.listener.onMouseUp = this.onMouseUp;
            }
            if (this.onMouseMove != undefined) {
                this.listener.onMouseMove = this.onMouseMove;
            }
            Mouse.addListener(this.listener);
        } else {
            delete this.listener.onMouseDown;
            delete this.listener.onMouseUp;
            delete this.listener.onMouseMove;
            Mouse.removeListener(this.listener);
        }
    };
    _r2.__set___use = function (bool) {
        if (bool) {
            this.onControl(true);
        } else {
            this.onControl(false);
        }
        return this.__get___use();
        <UNDERFLOW>;
    };
    _r2.__get___use = function () {
        return this.use;
    };
    _r2.listener = new Object();
    _r2.use = true;
}
ASSetPropFlags(_global.MouseListener.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("_use", _r2.__get___use, _r2.__set___use)'] */
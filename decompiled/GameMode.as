if (!_global.GameMode) {
    _global.GameMode = _r1 = function (scope) {
        this.scope = scope;
        this.modearr = [];
    };
    _r2 = _r1.prototype;
    _r2.addMode = function (input, modename) {
        this.modearr.push([String(input).toUpperCase(), modename]);
        trace(this.modearr);
    };
    _r2.checkOn = function () {
        this.listener.onKeyDown = Delegate.create(this, this.checkMode);
        Key.addListener(this.listener);
    };
    _r2.checkMode = function (key) {
        if (Key.isDown(13)) {
            _r2 = 0;
            while (_r2 < this.modearr.length) {
                if (this.modearr[_r2][0] == this.value) {
                    GameMode.mode = this.modearr[_r2][1];
                    this.scope.sound.play("snd_best");
                    this.scope.mode2x._y = 10;
                }
                _r2 = _r2 + 1;
            }
            this.value = "";
        } else {
            this.value = this.value + String.fromCharCode(Key.getCode());
        }
    };
    _r2.checkOff = function () {
        _r2 = this;
        Key.removeListener(this.listener);
        delete this.listener.onKeyDown;
    };
    _r2.listener = new Object();
    _r2.value = "";
    _r1.mode = "normal";
}
ASSetPropFlags(_global.GameMode.prototype, null, 1);
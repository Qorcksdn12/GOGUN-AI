if (!_global.AddNum) {
    _global.AddNum = _r1 = function (scope, mc_name, length) {
        this.scope = scope;
        this.mc_name = mc_name;
        this.length = length;
        this.num = new nhn.as2.security.SecurityNumber();
        this.xpos = [];
        this.digit = false;
        this.left = false;
        this.Update();
    };
    _r2 = _r1.prototype;
    _r2.setRange = function (bool, max, min) {
        if (bool) {
            this.num.isRange(true);
            if (max != null) {
                this.num.setRangeMAX(max);
            }
            if (min != null) {
                this.num.setRangeMIN(min);
            }
        } else {
            this.num.isRange(false);
        }
    };
    _r2.isSpeedHack = function (bool) {
        this.num.isSpeedHack(bool);
    };
    _r2.Add = function (num) {
        if (this.num.__get__value() + num >= 0) {
            this.num.value = this.num.value + int(num);
        } else {
            this.num.__set__value(0);
        }
        this.Update();
    };
    _r2.Update = function () {
        this.resetDisit();
        _r5 = this.num.__get__value().toString();
        _r6 = 0;
        _r4 = undefined;
        if (this.length > 1) {
            _r2 = 0;
            while (_r2 < this.length) {
                _r3 = undefined;
                _r4 = 10;
                if (this.left) {
                    if (_r2 < _r5.length) {
                        _r3 = Number(_r5.charAt(_r2));
                        if (_r3 > 0) {
                            _r4 = _r3;
                        }
                        this.scope[this.mc_name + _r2].gotoAndStop(_r4);
                    } else {
                        this.scope[this.mc_name + _r2].gotoAndStop(10);
                    }
                } else {
                    if (_r2 >= this.length - _r5.length) {
                        _r3 = Number(_r5.charAt(_r2 - _r6));
                        if (_r3 > 0) {
                            _r4 = _r3;
                        }
                        this.scope[this.mc_name + _r2].gotoAndStop(_r4);
                    } else {
                        _r6 = _r6 + 1;
                        this.scope[this.mc_name + _r2].gotoAndStop(10);
                    }
                }
                _r2 = _r2 + 1;
            }
        } else {
            if (this.num.__get__value() == 0) {
                _r4 = 10;
            } else {
                _r4 = this.num.value;
            }
            this.scope[this.mc_name + "0"].gotoAndStop(_r4);
        }
    };
    _r2.resetDisit = function () {
        if (this.digit) {
            _r2 = 0;
            while (_r2 < this.length) {
                this.scope[this.mc_name + _r2]._visible = false;
                _r2 = _r2 + 1;
            }
            _r3 = Number(String(this.num.__get__value()).length);
            if (this.left) {
                _r2 = 0;
                while (_r2 < _r3) {
                    this.scope[this.mc_name + _r2]._visible = true;
                    _r2 = _r2 + 1;
                }
            } else {
                _r2 = 0;
                while (_r2 < _r3) {
                    this.scope[this.mc_name + (this.length - _r2 - 1)]._visible = true;
                    _r2 = _r2 + 1;
                }
            }
        } else {
            _r2 = 0;
            while (_r2 < this.length) {
                this.scope[this.mc_name + _r2]._visible = true;
                _r2 = _r2 + 1;
            }
        }
    };
    _r2.__set___num = function (num) {
        if (!(this.num.__get__value() < 0) && !(num < 0)) {
            this.num.__set__value(int(num));
        } else {
            this.num.__set__value(0);
        }
        this.Update();
        return this.__get___num();
        <UNDERFLOW>;
    };
    _r2.__get___num = function () {
        return this.num.__get__value();
    };
    _r2.__set___digit = function (bool) {
        this.digit = bool;
        this.Update();
        return this.__get___digit();
        <UNDERFLOW>;
    };
    _r2.__set___left = function (bool) {
        this.left = bool;
        this.Update();
        return this.__get___left();
        <UNDERFLOW>;
    };
}
ASSetPropFlags(_global.AddNum.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("_digit", function () {\n}, _r2.__set___digit)', '_r2.addProperty("_left", function () {\n}, _r2.__set___left)', '_r2.addProperty("_num", _r2.__get___num, _r2.__set___num)'] */
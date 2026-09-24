if (!_global.nhn) {
    _global.nhn = new Object();
}
<UNDERFLOW>;
if (!_global.nhn.as2) {
    _global.nhn.as2 = new Object();
}
<UNDERFLOW>;
if (!_global.nhn.as2.security) {
    _global.nhn.as2.security = new Object();
}
<UNDERFLOW>;
if (!_global.nhn.as2.security.SecurityNumber) {
    nhn.as2.security.SecurityNumber = _r1 = function (_value, _bRange, _bSpeedHack) {
        if (_value == undefined || _value == null) {
            _value = 0;
        }
        if (_bRange == undefined || _bRange == null) {
            _bRange = false;
        }
        if (_bSpeedHack == undefined || _bSpeedHack == null) {
            _bSpeedHack = false;
        }
        this.crypto = new nhn.as2.crypt.TEA();
        _r8 = Math.random();
        _r2 = String(_r8);
        _r2 = _r2.substr(2, _r2.length - 2);
        _r7 = Math.random();
        _r3 = String(_r7);
        _r3 = _r3.substr(2, _r3.length - 2);
        this.key = _r2 + _r3;
        this.__set__value(_value);
        this.isRange(_bRange);
        this.isSpeedHack(_bSpeedHack);
    };
    _r2 = _r1.prototype;
    _r2.__get__value = function () {
        return Number(this.crypto.decrypt(this.data, this.key));
    };
    _r2.__set__value = function (_value) {
        if (this.bSecurity) {
            this.nClone = Number(this.crypto.decrypt(this.data, this.key));
            if (this.bRange) {
                if (this.nClone - this.rMIN > _value || this.nClone + this.rMAX < _value) {
                    _value = this.nClone;
                    this.data = this.crypto.encrypt(String(_value), this.key);
                    return undefined;
                }
            }
            if (this.bSpeedHack) {
                this.timerNew = Math.abs(getTimer() - (new Date()).getTime() + this.nGetTimer);
                if (Math.abs(this.timerNew - this.timerOld) > 16) {
                    _value = this.nClone;
                }
                this.timerOld = this.timerNew;
            }
        }
        this.data = this.crypto.encrypt(String(_value), this.key);
        return this.__get__value();
        <UNDERFLOW>;
    };
    _r2.setRangeMAX = function (_max) {
        if (_max == undefined || _max == null) {
            _max = 0;
        }
        this.rMAX = _max;
    };
    _r2.setRangeMIN = function (_min) {
        if (_min == undefined || _min == null) {
            _min = 0;
        }
        this.rMIN = _min;
    };
    _r2.isRange = function (bl) {
        if (bl == undefined || bl == null) {
            bl = false;
        }
        this.bRange = bl;
        this.bSecurity = this.bRange || this.bSpeedHack;
    };
    _r2.isSpeedHack = function (bl) {
        if (bl == undefined || bl == null) {
            bl = false;
        }
        this.bSpeedHack = bl;
        this.bSecurity = this.bRange || this.bSpeedHack;
        this.nGetTimer = (new Date()).getTime() - getTimer();
        this.timerOld = _r0 = Math.abs(getTimer() - (new Date()).getTime() + this.nGetTimer);
        this.timerNew = _r0;
    };
    _r2.key = null;
    _r2.crypto = null;
    _r2.bSecurity = false;
    _r2.rMAX = 0;
    _r2.rMIN = 0;
    _r2.bRange = false;
    _r2.bSpeedHack = false;
}
ASSetPropFlags(nhn.as2.security.SecurityNumber.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("value", _r2.__get__value, _r2.__set__value)'] */
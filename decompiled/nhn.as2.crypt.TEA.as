if (!_global.nhn) {
    _global.nhn = new Object();
}
<UNDERFLOW>;
if (!_global.nhn.as2) {
    _global.nhn.as2 = new Object();
}
<UNDERFLOW>;
if (!_global.nhn.as2.crypt) {
    _global.nhn.as2.crypt = new Object();
}
<UNDERFLOW>;
if (!_global.nhn.as2.crypt.TEA) {
    nhn.as2.crypt.TEA = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r2.encrypt = function (src, key) {
        _r5 = this.charsToLongs(this.strToChars(src));
        _r10 = this.charsToLongs(this.strToChars(key));
        _r9 = _r5.length;
        if (_r9 == 0) {
            return "";
        }
        if (_r9 == 1) {
            _r9 = _r9 + 1;
            _r5[_r9] = 0;
        }
        _r3 = _r5[_r9 - 1];
        _r4 = _r5[0];
        _r12 = 2654435769;
        _r6 = undefined;
        _r8 = undefined;
        _r11 = Math.floor(6 + 52 / _r9);
        _r7 = 0;
        while (true) {
            _r11 = _r11 - 1;
            if (!(_r11 > 0)) break;
            _r7 = _r7 + _r12;
            _r8 = _r7 >>> 2 & 3;
            _r2 = 0;
            while (_r2 < _r9 - 1) {
                _r4 = _r5[_r2 + 1];
                _r6 = (_r3 >>> 5 ^ _r4 << 2) + (_r4 >>> 3 ^ _r3 << 4) ^ (_r7 ^ _r4) + (_r10[_r2 & 3 ^ _r8] ^ _r3);
                _r5[_r2] = _r0 = _r5[_r2] + _r6;
                _r3 = _r0;
                _r2 = _r2 + 1;
            }
            _r4 = _r5[0];
            _r6 = (_r3 >>> 5 ^ _r4 << 2) + (_r4 >>> 3 ^ _r3 << 4) ^ (_r7 ^ _r4) + (_r10[_r2 & 3 ^ _r8] ^ _r3);
            _r5[_r9 - 1] = _r0 = _r5[_r9 - 1] + _r6;
            _r3 = _r0;
        }
        return this.charsToHex(this.longsToChars(_r5));
    };
    _r2.decrypt = function (src, key) {
        _r5 = this.charsToLongs(this.hexToChars(src));
        _r10 = this.charsToLongs(this.strToChars(key));
        _r9 = _r5.length;
        if (_r9 == 0) {
            return "";
        }
        _r3 = _r5[_r9 - 1];
        _r4 = _r5[0];
        _r11 = 2654435769;
        _r7 = undefined;
        _r8 = undefined;
        _r12 = Math.floor(6 + 52 / _r9);
        _r6 = _r12 * _r11;
        while (_r6 != 0) {
            _r8 = _r6 >>> 2 & 3;
            _r2 = _r9 - 1;
            while (_r2 > 0) {
                _r3 = _r5[_r2 - 1];
                _r7 = (_r3 >>> 5 ^ _r4 << 2) + (_r4 >>> 3 ^ _r3 << 4) ^ (_r6 ^ _r4) + (_r10[_r2 & 3 ^ _r8] ^ _r3);
                _r5[_r2] = _r0 = _r5[_r2] - _r7;
                _r4 = _r0;
                _r2 = _r2 - 1;
            }
            _r3 = _r5[_r9 - 1];
            _r7 = (_r3 >>> 5 ^ _r4 << 2) + (_r4 >>> 3 ^ _r3 << 4) ^ (_r6 ^ _r4) + (_r10[_r2 & 3 ^ _r8] ^ _r3);
            _r5[0] = _r0 = _r5[0] - _r7;
            _r4 = _r0;
            _r6 = _r6 - _r11;
        }
        return this.charsToStr(this.longsToChars(_r5));
    };
    _r2.charsToLongs = function (chars) {
        _r3 = new Array(Math.ceil(chars.length / 4));
        _r1 = 0;
        while (_r1 < _r3.length) {
            _r3[_r1] = chars[_r1 * 4] + (chars[_r1 * 4 + 1] << 8) + (chars[_r1 * 4 + 2] << 16) + (chars[_r1 * 4 + 3] << 24);
            _r1 = _r1 + 1;
        }
        return _r3;
    };
    _r2.longsToChars = function (longs) {
        _r3 = new Array();
        _r1 = 0;
        while (_r1 < longs.length) {
            _r3.push(longs[_r1] & 255, longs[_r1] >>> 8 & 255, longs[_r1] >>> 16 & 255, longs[_r1] >>> 24 & 255);
            _r1 = _r1 + 1;
        }
        return _r3;
    };
    _r2.charsToHex = function (chars) {
        _r4 = new String("");
        _r3 = new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f");
        _r1 = 0;
        while (_r1 < chars.length) {
            _r4 = _r4 + (_r3[chars[_r1] >> 4] + _r3[chars[_r1] & 15]);
            _r1 = _r1 + 1;
        }
        return _r4;
    };
    _r2.hexToChars = function (hex) {
        _r3 = new Array();
        _r1 = hex.substr(0, 2) != "0x" ? 0 : 2;
        while (_r1 < hex.length) {
            _r3.push(parseInt(hex.substr(_r1, 2), 16));
            _r1 = _r1 + 2;
        }
        return _r3;
    };
    _r2.charsToStr = function (chars) {
        _r3 = new String("");
        _r1 = 0;
        while (_r1 < chars.length) {
            _r3 = _r3 + String.fromCharCode(chars[_r1]);
            _r1 = _r1 + 1;
        }
        return _r3;
    };
    _r2.strToChars = function (str) {
        _r3 = new Array();
        _r1 = 0;
        while (_r1 < str.length) {
            _r3.push(str.charCodeAt(_r1));
            _r1 = _r1 + 1;
        }
        return _r3;
    };
}
ASSetPropFlags(nhn.as2.crypt.TEA.prototype, null, 1);
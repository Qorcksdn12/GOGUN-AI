if (!_global.CoinItem) {
    _global.CoinItem = _r1 = function (stage) {
        this.stage = stage.createEmptyMovieClip("item", 1);
        this.effect = stage.createEmptyMovieClip("effect", 2);
        this.itemdata = new ItemData();
        this.itemwait = [];
        this.itemarr = [];
        this.boxarr = [];
        this.parr = [];
    };
    _r2 = _r1.prototype;
    _r2.addItem = function (map, testitem) {
        if (this.itemwait.length <= 0) {
            _r3 = [];
            if (testitem != undefined) {
                _r3 = testitem;
            } else {
                _r3 = this.itemdata.getItem(map);
            }
            _r2 = 0;
            while (_r2 < _r3.length) {
                this.itemwait.push(_r3[_r2]);
                _r2 = _r2 + 1;
            }
            if (this.pitem < 8) {
                this.pitem = this.pitem + 1;
            } else {
                this.pitem = 0;
            }
            this.parr[this.pitem] = this.getItemNum(_r3);
            if (this.parr[this.pitem] <= 0) {
                this.parr[this.pitem] = -1;
            }
        }
    };
    _r2.createItem = function (x, y) {
        _r4 = [];
        _r6 = [];
        _r4 = _r4.concat(this.itemwait.shift());
        if (_r4.length > 0) {
            this.depth = this.depth + 1;
            _r5 = this.stage.createEmptyMovieClip("item" + this.depth, this.depth);
            _r5._x = x;
            _r5._y = y;
            _r2 = 0;
            while (_r2 < _r4.length) {
                _r3 = _r5.attachMovie("id_item", "item_" + _r2, _r2);
                if (_r4[_r2] < 100) {
                    _r3.gotoAndStop(1);
                } else {
                    _r3.gotoAndStop(2);
                    _r4[_r2] = _r4[_r2] - 100;
                }
                _r3._x = -58.5 + _r4[_r2] % 4 * 37.5;
                _r3._y = -480 + Math.floor(_r4[_r2] / 4) * 37;
                _r3.cacheAsBitmap = true;
                _r3.pitem = this.pitem;
                _r6.push(_r3);
                _r2 = _r2 + 1;
            }
            _r5.cacheAsBitmap = true;
            this.itemarr.push(_r6);
            this.boxarr.push(_r5);
        }
    };
    _r2.eatItem = function (mc) {
        _r3 = 0;
        while (_r3 < this.itemarr.length) {
            _r2 = 0;
            while (_r2 < this.itemarr[_r3].length) {
                if (mc.hitTest(this.itemarr[_r3][_r2])) {
                    if (this.itemarr[_r3][_r2]._currentframe == 1) {
                        this.parr[this.itemarr[_r3][_r2].pitem] = this.parr[this.itemarr[_r3][_r2].pitem] - 1;
                    }
                    if (this.itemarr[_r3][_r2]._currentframe == 1) {
                        this.addPoint(2);
                    } else {
                        this.addPoint(1);
                    }
                    this.onBonus();
                    this.itemarr[_r3][_r2].coin.gotoAndStop(2);
                    this.itemarr[_r3].splice(_r2, 1);
                    _r2 = _r2 - 1;
                }
                _r2 = _r2 + 1;
            }
            _r3 = _r3 + 1;
        }
    };
    _r2.deleteItem = function (x) {
        _r2 = 0;
        while (_r2 < this.boxarr.length) {
            if (this.boxarr[_r2]._x < x) {
                this.itemarr.splice(_r2, 1);
                this.boxarr[_r2].removeMovieClip();
                this.boxarr.splice(_r2, 1);
                _r2 = _r2 - 1;
            }
            _r2 = _r2 + 1;
        }
    };
    _r2.onBonus = function () {
        _r2 = 0;
        while (_r2 < this.parr.length) {
            if (this.parr[_r2] == 0) {
                this.addPoint(3);
                this.bonusEffect();
                this.parr[_r2] = -1;
            }
            _r2 = _r2 + 1;
        }
    };
    _r2.getItemNum = function (item) {
        _r4 = 0;
        _r2 = 0;
        while (_r2 < item.length) {
            _r1 = 0;
            while (_r1 < item[_r2].length) {
                if (item[_r2][_r1] < 100) {
                    _r4 = _r4 + 1;
                }
                _r1 = _r1 + 1;
            }
            _r2 = _r2 + 1;
        }
        return _r4;
    };
    _r2.__get___itemarr = function () {
        return this.itemarr;
    };
    _r2.__set___itemarr = function (arr) {
        this.itemarr = arr;
        return this.__get___itemarr();
        <UNDERFLOW>;
    };
    _r2.__get___boxarr = function () {
        return this.boxarr;
    };
    _r2.__set___boxarr = function (arr) {
        this.boxarr = arr;
        return this.__get___boxarr();
        <UNDERFLOW>;
    };
    _r2.depth = 1;
    _r2.depthe = 1;
    _r2.pitem = 0;
    _r2.bonus = false;
}
ASSetPropFlags(_global.CoinItem.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("_boxarr", _r2.__get___boxarr, _r2.__set___boxarr)', '_r2.addProperty("_itemarr", _r2.__get___itemarr, _r2.__set___itemarr)'] */
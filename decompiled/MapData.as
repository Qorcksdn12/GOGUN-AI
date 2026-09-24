if (!_global.MapData) {
    _global.MapData = _r1 = function () {
        this.level0 = [];
        this.level1 = [];
        this.level2 = [];
        this.level3 = [];
        this.level4 = [];
        this.level5 = [];
        this.level6 = [];
        this.setMap();
    };
    _r2 = _r1.prototype;
    _r2.setMap = function () {
        this.level0.push([2, 2, 2]);
        this.level0.push([2, 2, 2, 2, 2]);
        this.level1.push([2, 2, 1, 2, 2]);
        this.level2.push([2, 2, 1, 1, 2, 2]);
        this.level2.push([2, 2, 1, 3, 1, 2, 2]);
        this.level2.push([2, 2, 2, 1, 1, 3, 1, 2, 2, 2]);
        this.level2.push([2, 2, 2, 1, 3, 1, 1, 2, 2, 2]);
        this.level3.push([2, 2, 1, 1, 2, 2]);
        this.level3.push([2, 2, 1, 1, 3, 1, 1, 2, 2, 2]);
        this.level3.push([2, 2, 1, 1, 1, 3, 1, 1, 2, 2]);
        this.level3.push([2, 2, 1, 1, 3, 1, 1, 1, 2, 2]);
        this.level3.push([2, 2, 1, 3, 1, 3, 1, 2, 2, 2]);
        this.level4.push([2, 2, 1, 1, 2, 2]);
        this.level4.push([2, 2, 1, 1, 1, 3, 1, 1, 2, 2]);
        this.level4.push([2, 2, 1, 1, 3, 1, 1, 1, 2, 2]);
        this.level4.push([2, 2, 1, 3, 1, 3, 1, 2, 2, 2]);
        this.level4.push([2, 1, 3, 1, 3, 1, 3, 1, 2, 2]);
        this.level5.push([2, 1, 3, 1, 3, 1, 3, 1, 2, 2]);
        this.level5.push([2, 2, 2, 2, 1, 1, 1, 2, 2, 2]);
        this.level5.push([2, 1, 3, 1, 3, 1, 3, 1, 3, 1]);
        this.level5.push([1, 3, 1, 3, 1, 3, 1, 3, 1, 3]);
        this.level5.push([2, 2, 1, 3, 1, 3, 1, 1, 2, 2]);
        this.level6.push([2, 2, 2, 2, 1, 1, 1, 2, 2, 2]);
        this.level6.push([2, 1, 3, 1, 3, 1, 3, 1, 3, 1]);
        this.level6.push([1, 3, 1, 3, 1, 3, 1, 3, 1, 3]);
        this.level6.push([1, 3, 1, 3, 1, 1, 3, 1, 3, 1]);
    };
    _r2.getMap = function (level) {
        _r3 = 0;
        _r4 = [];
        level = level + 1;
        if (level == 1) {
            _r3 = 75;
        } else {
            if (level == 2) {
                _r3 = 50;
            } else {
                if (level == 3) {
                    _r3 = 40;
                } else {
                    if (level == 4) {
                        _r3 = 10;
                    } else {
                        if (level == 5) {
                            _r3 = 30;
                        } else {
                            if (level == 6) {
                                _r3 = 0;
                            }
                        }
                    }
                }
            }
        }
        if (random(100) < _r3) {
            _r4 = this.level0[random(this.level0.length)];
        } else {
            _r4 = this["level" + level][random(this["level" + level].length)];
        }
        return _r4;
    };
    _r2.level0 = [];
    _r2.level1 = [];
    _r2.level2 = [];
    _r2.level3 = [];
    _r2.level4 = [];
    _r2.level5 = [];
    _r2.level6 = [];
}
ASSetPropFlags(_global.MapData.prototype, null, 1);
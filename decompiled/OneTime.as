if (!_global.OneTime) {
    _global.OneTime = _r1 = function (time) {
        this.time = time;
        if (time != undefined) {
            this.onStart();
        }
    };
    _r2 = _r1.prototype;
    _r2.onTime = function () {
        this.onPlay();
        this.stime = _r0 = this.stime + 1;
        if (_r0 >= this.etime) {
            clearInterval(this.interval);
            this.status = false;
        }
    };
    _r2.onStop = function () {
        clearInterval(this.interval);
        this.status = false;
    };
    _r2.onStart = function () {
        if (!this.status) {
            this.stime = 0;
            this.status = true;
            this.interval = setInterval(this, "onTime", this.time * 1000);
        }
    };
    _r2.__set___time = function (num) {
        this.time = num;
        return this.__get___time();
        <UNDERFLOW>;
    };
    _r2.__get___time = function () {
        return this.time;
    };
    _r2.__set___etime = function (num) {
        this.etime = num;
        return this.__get___etime();
        <UNDERFLOW>;
    };
    _r2.__get___etime = function () {
        return this.etime;
    };
    _r2.stime = 0;
    _r2.etime = 1;
    _r2.time = 1;
    _r2.status = false;
}
ASSetPropFlags(_global.OneTime.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("_etime", _r2.__get___etime, _r2.__set___etime)', '_r2.addProperty("_time", _r2.__get___time, _r2.__set___time)'] */
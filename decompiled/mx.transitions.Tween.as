if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions) {
    _global.mx.transitions = new Object();
}
<UNDERFLOW>;
if (!_global.mx.transitions.Tween) {
    mx.transitions.Tween = _r1 = function (obj, prop, func, begin, finish, duration, useSeconds) {
        mx.transitions.OnEnterFrameBeacon.init();
        if (!arguments.length) {
            return undefined;
        }
        this.obj = obj;
        this.prop = prop;
        this.begin = begin;
        this.__set__position(begin);
        this.__set__duration(duration);
        this.useSeconds = useSeconds;
        if (func) {
            this.func = func;
        }
        this.__set__finish(finish);
        this._listeners = [];
        this.addListener(this);
        this.start();
    };
    _r2 = _r1.prototype;
    _r2.__set__time = function (t) {
        this.prevTime = this._time;
        if (t > this.__get__duration()) {
            if (this.looping) {
                this.rewind(t - this._duration);
                this.update();
                this.broadcastMessage("onMotionLooped", this);
            } else {
                if (this.useSeconds) {
                    this._time = this._duration;
                    this.update();
                }
                this.stop();
                this.broadcastMessage("onMotionFinished", this);
            }
        } else {
            if (t < 0) {
                this.rewind();
                this.update();
            } else {
                this._time = t;
                this.update();
            }
        }
        return this.__get__time();
        <UNDERFLOW>;
    };
    _r2.__get__time = function () {
        return this._time;
    };
    _r2.__set__duration = function (d) {
        this._duration = !(d == null || !(d > 0)) ? d : _global.Infinity;
        return this.__get__duration();
        <UNDERFLOW>;
    };
    _r2.__get__duration = function () {
        return this._duration;
    };
    _r2.__set__FPS = function (fps) {
        _r2 = this.isPlaying;
        this.stopEnterFrame();
        this._fps = fps;
        if (_r2) {
            this.startEnterFrame();
        }
        return this.__get__FPS();
        <UNDERFLOW>;
    };
    _r2.__get__FPS = function () {
        return this._fps;
    };
    _r2.__set__position = function (p) {
        this.setPosition(p);
        return this.__get__position();
        <UNDERFLOW>;
    };
    _r2.setPosition = function (p) {
        this.prevPos = this._pos;
        this._pos = _r0 = p;
        this.obj[this.prop] = _r0;
        this.broadcastMessage("onMotionChanged", this, this._pos);
        updateAfterEvent();
    };
    _r2.__get__position = function () {
        return this.getPosition();
    };
    _r2.getPosition = function (t) {
        if (t == undefined) {
            t = this._time;
        }
        return this.func(t, this.begin, this.change, this._duration);
    };
    _r2.__set__finish = function (f) {
        this.change = f - this.begin;
        return this.__get__finish();
        <UNDERFLOW>;
    };
    _r2.__get__finish = function () {
        return this.begin + this.change;
    };
    _r2.continueTo = function (finish, duration) {
        this.begin = this.position;
        this.__set__finish(finish);
        if (duration != undefined) {
            this.__set__duration(duration);
        }
        this.start();
    };
    _r2.yoyo = function () {
        this.continueTo(this.begin, this.__get__time());
    };
    _r2.startEnterFrame = function () {
        if (this._fps == undefined) {
            _global.MovieClip.addListener(this);
        } else {
            this._intervalID = setInterval(this, "onEnterFrame", 1000 / this._fps);
        }
        this.isPlaying = true;
    };
    _r2.stopEnterFrame = function () {
        if (this._fps == undefined) {
            _global.MovieClip.removeListener(this);
        } else {
            clearInterval(this._intervalID);
        }
        this.isPlaying = false;
    };
    _r2.start = function () {
        this.rewind();
        this.startEnterFrame();
        this.broadcastMessage("onMotionStarted", this);
    };
    _r2.stop = function () {
        this.stopEnterFrame();
        this.broadcastMessage("onMotionStopped", this);
    };
    _r2.resume = function () {
        this.fixTime();
        this.startEnterFrame();
        this.broadcastMessage("onMotionResumed", this);
    };
    _r2.rewind = function (t) {
        this._time = t != undefined ? t : 0;
        this.fixTime();
        this.update();
    };
    _r2.fforward = function () {
        this.__set__time(this._duration);
        this.fixTime();
    };
    _r2.nextFrame = function () {
        if (this.useSeconds) {
            this.__set__time((getTimer() - this._startTime) / 1000);
        } else {
            this.__set__time(this._time + 1);
        }
    };
    _r2.onEnterFrame = function () {
        this.nextFrame();
    };
    _r2.prevFrame = function () {
        if (!this.useSeconds) {
            this.__set__time(this._time - 1);
        }
    };
    _r2.toString = function () {
        return "[Tween]";
    };
    _r2.fixTime = function () {
        if (this.useSeconds) {
            this._startTime = getTimer() - this._time * 1000;
        }
    };
    _r2.update = function () {
        this.__set__position(this.getPosition(this._time));
    };
    _r1.version = "1.1.0.52";
    _r1.__initBeacon = mx.transitions.OnEnterFrameBeacon.init();
    _r1.__initBroadcaster = mx.transitions.BroadcasterMX.initialize(mx.transitions.Tween.prototype, true);
    _r2.func = function (t, b, c, d) {
        return c * t / d + b;
    };
}
ASSetPropFlags(mx.transitions.Tween.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("FPS", _r2.__get__FPS, _r2.__set__FPS)', '_r2.addProperty("duration", _r2.__get__duration, _r2.__set__duration)', '_r2.addProperty("finish", _r2.__get__finish, _r2.__set__finish)', '_r2.addProperty("position", _r2.__get__position, _r2.__set__position)', '_r2.addProperty("time", _r2.__get__time, _r2.__set__time)'] */
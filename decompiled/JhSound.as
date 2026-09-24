if (!_global.JhSound) {
    _global.JhSound = _r1 = function (mc) {
        this.sound = new Sound(mc);
    };
    _r2 = _r1.prototype;
    _r2.play = function (str, num) {
        this.message("play : " + str);
        if (num == undefined) {
            num = 1;
        }
        this.sound.attachSound(str);
        this.sound.start(0, num);
    };
    _r2.stop = function (str) {
        this.message("stop : " + str);
        this.sound.stop(str);
    };
    _r2.allStop = function () {
        this.message("all stop");
        this.sound.stop();
    };
    _r2.setVolume = function (num) {
        this.message("setVolume : " + num);
        this.volume = num;
        this.sound.setVolume(this.volume);
    };
    _r2.soundOn = function () {
        this.message("soundOn");
        this.sound.setVolume(this.volume);
    };
    _r2.soundOff = function () {
        this.message("soundOff");
        this.sound.setVolume(0);
    };
    _r2.setMsg = function (bool) {
        if (bool) {
            this.msg = true;
        } else {
            this.msg = false;
        }
    };
    _r2.message = function (str) {
        if (this.msg) {
            trace(str);
        }
    };
    _r2.volume = 100;
    _r2.msg = false;
}
ASSetPropFlags(_global.JhSound.prototype, null, 1);
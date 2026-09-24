if (!_global.SetGame) {
    _global.SetGame = _r1 = function (scope) {
        this.scope = scope;
        this.onServerSend("gamestart");
        this.initialize();
    };
    _r2 = _r1.prototype;
    _r2.initialize = function () {
        this.sound = this.scope.sound;
        this.sound.stop("snd_titlebg");
        this.sound.play("snd_gamebg", 9999);
        this.mouse = new MouseListener();
        this.mouse.onMouseDown = Delegate.create(this, this.onMouseDown);
        this.mouse.onMouseUp = Delegate.create(this, this.onMouseUp);
        this.mouse.__set___use(true);
        if (GameMode.mode == "2x") {
            this.addspeed = 1.5;
        }
        this.setMovieClip();
        this.initMap();
        this.scope.editor.prevmap.text = "";
        this.scope.editor.nextmap.text = "";
    };
    _r2.setMovieClip = function () {
        this.stage = this.scope.createEmptyMovieClip("stage", 1);
        this.stage.scrollRect = new flash.geom.Rectangle(0, 0, 640, 480);
        this.bstage = this.stage.createEmptyMovieClip("bstage", 1);
        this.rope = this.stage.createEmptyMovieClip("rope", 2);
        this.stick = this.stage.attachMovie("id_stick", "stick_mc", 3);
        this.stick._visible = false;
        this.itemstage = this.stage.createEmptyMovieClip("item", 4);
        this.itemstage.scrollRect = new flash.geom.Rectangle(0, 0, 640, 480);
        this.coinitem = new CoinItem(this.itemstage);
        this.coinitem.addPoint = Delegate.create(this, this.addPoint);
        this.coinitem.bonusEffect = Delegate.create(this, this.onEffect, "bonus");
        this.gstage = this.stage.createEmptyMovieClip("gogoon", 5);
        this.gogoon = this.gstage.attachMovie("id_gogoon", "gogoon_mc", 4, {_x: 200, _y: this.ground});
        this.gogoon.hit_mc._visible = false;
        this.effect = this.stage.createEmptyMovieClip("effect", 6);
        this.uistage = this.stage.createEmptyMovieClip("ui", 7);
        this.uistage.attachMovie("id_score", "score", 1, {_x: 11, _y: 8});
        this.score = new AddNum(this.uistage.score, "score", 6);
        this.score.__set___digit(true);
        this.score.__set___left(true);
        this.score.setRange(true, 200, 0);
        this.score.isSpeedHack(true);
        this.ui_run = this.uistage.attachMovie("id_running", "running", 2, {_x: 50, _y: 463});
        this.catstone = this.scope.catstone_mc;
        this.best = new AddNum(this.catstone, "score", 7);
        if (this.scope.bestscore > 0) {
            this.best.__set___num(this.scope.bestscore);
        } else {
            this.best.__set___num(0);
        }
        this.effect_mc = this.gstage.createEmptyMovieClip("shadow1", 2);
        this.effect_mc2 = this.gstage.createEmptyMovieClip("shadow2", 1);
        this.bitmapdata = new flash.display.BitmapData(200, 200, true, 0);
        this.effect_mc.attachBitmap(this.bitmapdata, 1);
        this.effect_mc._alpha = 50;
        this.bitmapdata2 = new flash.display.BitmapData(200, 200, true, 0);
        this.effect_mc2.attachBitmap(this.bitmapdata2, 0);
        this.effect_mc2._alpha = 20;
        this.scope.cloude_mc.cacheAsBitmap = true;
    };
    _r2.onMouseDown = function () {
        this.click = true;
        if (this.status == "run") {
            this.gJump();
        } else {
            if (this.status == "jump") {
                this.gShoot();
            }
        }
    };
    _r2.onMouseUp = function () {
        this.click = false;
    };
    _r2.onKeyDown = function () {
        if (Key.isDown(32) && !this.spacebar) {
            this.spacebar = true;
            this.onMouseDown();
        }
    };
    _r2.onKeyUp = function () {
        this.spacebar = false;
        this.onMouseUp();
    };
    _r2.onStart = function () {
        this.gRun();
        this.stage.onEnterFrame = Delegate.create(this, this.onEnterFrame);
    };
    _r2.initMap = function () {
        this.map = [];
        this.blockarr = [];
        this.item = [];
        this.testmap = [];
        this.testitem = [];
        this.mapdata = new MapData();
        _r2 = 0;
        while (_r2 < 6) {
            this.createBlock(2, _r2 * this.block_w);
            _r2 = _r2 + 1;
        }
        this.count = 0;
    };
    _r2.gRun = function () {
        this.status = "run";
        this.click = false;
        this.gogoon.gotoAndStop("run");
        this.gogoon.onEnterFrame = Delegate.create(this, this.gRun_EnterFrame);
        this.sound.play("snd_run", 999);
    };
    _r2.gRun_EnterFrame = function () {
        if (!this.groundCheck()) {
            this.gameOver();
        }
    };
    _r2.gJump = function () {
        this.status = "jump";
        this.gogoon.gotoAndStop("jump");
        this.sound.stop("snd_run");
        this.sound.play("snd_ropeup");
        this.gogoon.dy = this.dy * this.addspeed;
        this.gogoon.onEnterFrame = Delegate.create(this, this.gJump_EnterFrame, this.gravity);
    };
    _r2.gJump_EnterFrame = function (gravity) {
        if (this.gogoon.dy > -20) {
            this.gogoon.dy = this.gogoon.dy - gravity * Math.pow(this.addspeed, 2);
        }
        this.gogoon._y = this.gogoon._y - this.gogoon.dy;
        if (this.gogoon.dy < 0) {
            if (this.status != "shoot") {
                this.status = "jump";
            }
            if (!(this.gogoon._y < this.ground) && this.groundCheck()) {
                this.gogoon._y = this.ground;
                this.rope.clear();
                this.stick._visible = false;
                delete this.rope.onEnterFrame;
                delete this.gogoon.onEnterFrame;
                this.gRun();
                this.sound.stop("snd_spin");
            }
            if (this.dieCheck(470)) {
                this.gameOver();
            }
        }
    };
    _r2.gShoot = function () {
        this.status = "shoot";
        this.gogoon.gotoAndStop("shoot");
        this.sound.stop("snd_spin");
        this.sound.play("snd_shoot");
        this.rope.tx = GlobalTarget.getxy(this.gogoon.ropepos)._x - GlobalTarget.getxy(this.stage)._x;
        this.rope.ty = GlobalTarget.getxy(this.gogoon.ropepos)._y - GlobalTarget.getxy(this.stage)._y;
        this.stick._visible = true;
        this.rope.onEnterFrame = Delegate.create(this, this.gShoot_EnterFrame);
    };
    _r2.gShoot_EnterFrame = function () {
        if (this.rope.ty > 0) {
            this.rope.ty = _r0 = this.rope.ty - (this.ropespeed - 5);
            this.rope.tx = _r0 = this.rope.tx + (this.ropespeed + 5);
            this.drawLine(_r0, _r0);
            this.rope.arrow._x = this.rope.arrow._x + this.ropespeed;
            this.rope.arrow._y = this.rope.arrow._y - this.ropespeed;
            this.stick._x = this.rope.tx;
            this.stick._y = this.rope.ty;
            _r2 = {_x: this.rope.tx + GlobalTarget.getxy(this.stage)._x, _y: this.rope.ty + GlobalTarget.getxy(this.stage)._y};
            this.stick._rotation = GlobalTarget.getsec(GlobalTarget.getxy(this.gogoon.ropepos), _r2) * 57.295779513;
            if (this.checkRope()) {
                this.gRope();
            }
        } else {
            this.rope.clear();
            this.stick._visible = false;
            delete this.rope.onEnterFrame;
            this.status = "jump";
        }
    };
    _r2.drawLine = function (tx, ty) {
        this.rope.clear();
        this.rope.lineStyle(1, 9878196, 100);
        this.rope.moveTo(GlobalTarget.getxy(this.gogoon.ropepos)._x - GlobalTarget.getxy(this.stage)._x, GlobalTarget.getxy(this.gogoon.ropepos)._y - GlobalTarget.getxy(this.stage)._y);
        this.rope.lineTo(tx, ty);
    };
    _r2.checkRope = function () {
        _r2 = 0;
        while (_r2 < this.blockarr.length) {
            if (this.blockarr[_r2].rope_pos.hitTest(this.rope.tx, this.rope.ty, false)) {
                return true;
            }
            _r2 = _r2 + 1;
        }
        return false;
    };
    _r2.gRope = function () {
        delete this.gogoon.onEnterFrame;
        this.gogoon.gotoAndStop("rope");
        this.status = "rope";
        this.sound.play("snd_ropecatch");
        this.gogoon.dy = 15 * this.addspeed;
        if (this.rope.ty < 125) {
            this.rope.tx = this.rope.tx - (125 - this.rope.ty - 5);
        }
        this.rope.ty = 125;
        this.stick._rotation = -80;
        this.stick.gotoAndStop(2);
        this.rope.onEnterFrame = Delegate.create(this, this.gRope_EnterFrame);
    };
    _r2.gRope_EnterFrame = function () {
        if (!this.dieCheck(550)) {
            this.rope.tx = _r0 = this.rope.tx - this.speed * this.addspeed;
            this.drawLine(_r0, this.rope.ty);
            this.stick._y = this.rope.ty;
            this.stick._x = this.rope.tx;
            _r2 = {_x: this.rope.tx, _y: this.rope.ty};
            this.gogoon.body._rotation = GlobalTarget.getsec(this.gogoon.body, _r2) * 57.295779513 + 70;
            if (this.click) {
                if (this.gogoon.dy > -30) {
                    this.gogoon.dy = this.gogoon.dy - this.gravity * Math.pow(this.addspeed, 2);
                }
                if (this.gogoon._y < this.rope.ty + 50) {
                    this.gSpin();
                }
            } else {
                if (this.gogoon.dy < 30) {
                    this.gogoon.dy = this.gogoon.dy + this.gravity * Math.pow(this.addspeed, 2);
                }
            }
            this.gogoon._y = this.gogoon._y + this.gogoon.dy;
            if (this.gogoon.body._rotation < -70) {
                this.gSpin();
            }
            if (this.rope.tx < 70) {
                this.gSpin();
            }
        } else {
            this.gameOver();
        }
    };
    _r2.gSpin = function () {
        delete this.rope.onEnterFrame;
        this.rope.clear();
        this.stick._visible = false;
        this.status = "spin";
        this.gogoon.gotoAndStop("spin");
        this.sound.play("snd_spin", 999);
        this.gogoon.dy = this.dy + 15 * this.addspeed;
        this.gogoon.onEnterFrame = Delegate.create(this, this.gJump_EnterFrame, this.gravity * 1.5);
    };
    _r2.createBlock = function (type, x) {
        if (type == 4) {
            this.goFinish();
        }
        this.depth = this.depth + 1;
        _r2 = this.bstage.attachMovie("id_block", "block_" + this.depth, this.depth);
        _r2.cacheAsBitmap = true;
        _r2.gotoAndStop(type);
        this.blockarr.push(_r2);
        _r2._x = x;
        _r2._y = 520;
        _r2.type = type;
        if (!this.test_map) {
            this.count = this.count + 1;
            if (this.count >= this.maxcount[this.level]) {
                this.levelUp();
            }
        }
    };
    _r2.levelUp = function () {
        if (!this.test_map) {
            this.level = this.level + 1;
            if (this.level <= 5) {
                this.count = 0;
                if (this.level < 3) {
                    this.speed = this.speed + 3;
                } else {
                    this.speed = this.speed + 2;
                }
                trace("level : " + this.level + ", speed : " + this.speed * this.addspeed);
                this.onEffect("speedup");
            } else {
                this.count = 0;
                trace("엔딩");
                this.map.push(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2);
            }
        }
    };
    _r2.goFinish = function () {
        this.bitmapdata.dispose();
        this.bitmapdata2.dispose();
        delete this.stage.onEnterFrame;
        this.speed = 0;
        this.mouse.__set___use(false);
        _r2 = this;
        this.stage.onEnterFrame = Delegate.create(this, this.onFinish);
        this.onFade("ending");
    };
    _r2.onFinish = function () {
        this.gogoon._x = this.gogoon._x + 30;
        if (this.scope._currentframe == 40) {
            delete this.stage.onEnterFrame;
            this.onDestroy();
            this.onServerSend("gameover");
            _r2 = new OneTime();
            _r2.__set___time(10);
            _r2.onPlay = Delegate.create(this, this.onServerSend, "viewrank");
            _r2.onStart();
        }
    };
    _r2.onFade = function (frame) {
        _r2 = this.scope.attachMovie("id_fadeinout", "fadeinout", 10);
        _r2.frame = frame;
        this.sound.play("snd_fadeinout");
    };
    _r2.onEnterFrame = function () {
        this.way = this.way + this.speed * this.addspeed;
        this.nextway = this.nextway + this.speed * this.addspeed;
        _r2 = 0;
        while (_r2 < this.blockarr.length) {
            this.blockarr[_r2]._x = this.blockarr[_r2]._x - this.speed * this.addspeed;
            _r2 = _r2 + 1;
        }
        _r2 = 0;
        while (_r2 < this.coinitem.__get___boxarr().length) {
            this.coinitem.__get___boxarr()[_r2]._x = this.coinitem.__get___boxarr()[_r2]._x - this.speed * this.addspeed;
            _r2 = _r2 + 1;
        }
        _r4 = this.block_w * 5 - (this.nextway - this.block_w);
        if (this.block_w <= this.nextway) {
            if (this.map.length <= 0) {
                _r3 = [];
                if (this.test_map) {
                    _r3 = this.testmap[random(this.testmap.length)];
                } else {
                    _r3 = this.mapdata.getMap(this.level);
                }
                this.map = this.map.concat(_r3);
                if (this.test_item) {
                    this.coinitem.addItem(this.map, this.testitem);
                } else {
                    this.coinitem.addItem(this.map);
                }
                this.scope.editor.prevmap.text = this.scope.editor.nextmap.text;
                this.scope.editor.nextmap.text = this.map;
            }
            _r5 = Number(this.map.shift());
            this.createBlock(_r5, _r4);
            this.coinitem.createItem(_r4, 520);
            this.coinitem.deleteItem(0 - this.block_w);
            this.deleteBlock();
            this.nextway = this.nextway - this.block_w;
        }
        this.coinitem.eatItem(this.gogoon.body.item_pos);
        this.shadowEffect();
        this.updateUI();
        this.scope.cloude_mc._x = this.scope.cloude_mc._x - this.speed * this.addspeed / 4;
        if (this.scope.cloude_mc._x < -832) {
            this.scope.cloude_mc._x = 832 + this.scope.cloude_mc._x;
        }
    };
    _r2.updateUI = function () {
        this.ui_run.face_mc._x = this.count / this.maxcount[this.level] * 90 + 90 * this.level;
        if (this.best.__get___num() < this.score.__get___num()) {
            if (this.scope.bestscore > 0) {
                if (!this.record) {
                    this.onEffect("best");
                }
                this.record = true;
                this.scope.bestscore = this.best.__set___num(this.score._num);
            }
        }
    };
    _r2.changeFace = function () {
        this.facetime.onStop();
        this.catstone.head_mc.gotoAndStop("suprise");
        this.facetime = new OneTime(5);
        var owner = this;
        this.facetime.onPlay = function () {
            owner.catstone.head_mc.gotoAndStop("sleep");
        };
    };
    _r2.shadowEffect = function () {
        this.effectarr.push([this.gogoon._x, this.gogoon._y]);
        if (this.effectarr.length > 3) {
            this.effectarr.shift();
        }
        if (this.effectarr.length > 0) {
            this.bitmapdata.fillRect(new flash.geom.Rectangle(0, 0, 200, 200), 0);
            if (this.effectarr.length > 1) {
                this.effect_mc._x = this.effectarr[1][0] - 100;
                this.effect_mc._y = this.effectarr[1][1] - 100;
                _r3 = new flash.geom.Matrix();
                _r3.translate(100, 100);
                this.bitmapdata.draw(this.gogoon, _r3);
            }
            this.bitmapdata2.fillRect(new flash.geom.Rectangle(0, 0, 200, 200), 0);
            if (this.effectarr.length > 0) {
                this.effect_mc2._x = this.effectarr[0][0] - 100;
                this.effect_mc2._y = this.effectarr[0][1] - 100;
                _r2 = new flash.geom.Matrix();
                _r2.translate(100, 100);
                this.bitmapdata2.draw(this.gogoon, _r2);
            }
        }
    };
    _r2.speedEffect = function () {
        _r4 = this.effect.createEmptyMovieClip("linestage", 4);
        _r4._x = 640;
        _r3 = 0;
        while (_r3 < 300) {
            _r2 = _r4.createEmptyMovieClip("line" + _r3, _r3);
            _r2.lineStyle(2 + random(2), 16777215, 10 + random(10));
            _r2.lineTo(100 + random(100), 0);
            _r2._x = random(2000);
            _r2._y = random(480);
            _r3 = _r3 + 1;
        }
        _r6 = new mx.transitions.Tween(_r4, "_x", mx.transitions.easing.Regular.easeIn, 640, -2500, 1, true);
        _r5 = new mx.transitions.Tween(_r4, "_alpha", mx.transitions.easing.Regular.easeIn, 100, 0, 1, true);
        _r5.onMotionFinished = function () {
            this.obj.removeMovieClip();
        };
    };
    _r2.onEffect = function (type) {
        if (type == "bonus") {
            this.sound.play("snd_coinbonus");
            this.catstone.head_mc.gotoAndStop("eyes");
            this.effect.attachMovie("id_bonus_effect", "bonus", 2, {_x: 191, _y: 237});
        } else {
            if (type == "speedup") {
                this.gogoon.effect_mc.gotoAndPlay(2);
                this.changeFace();
                this.sound.play("snd_speedup");
                this.effect.attachMovie("id_speedup_effect", "speedup", 1, {_x: 88, _y: 363});
            } else {
                if (type == "best") {
                    this.changeFace();
                    this.sound.play("snd_best");
                    this.effect.attachMovie("id_best_effect", "best", 3, {_x: 474, _y: 328});
                }
            }
        }
    };
    _r2.deleteBlock = function () {
        this.blockarr.shift().removeMovieClip();
    };
    _r2.groundCheck = function () {
        _r2 = 0;
        while (_r2 < this.blockarr.length) {
            if (this.blockarr[_r2].ground_pos.hitTest(this.gogoon.hit_mc)) {
                return true;
            }
            _r2 = _r2 + 1;
        }
        return false;
    };
    _r2.dieCheck = function (num) {
        if (this.gogoon._y > num) {
            return true;
        } else {
            return false;
        }
    };
    _r2.addPoint = function (type) {
        if (type == 1) {
            this.score.Add(5.1);
            this.sound.play("snd_silvercoin");
        } else {
            if (type == 2) {
                this.score.Add(50 - this.level * 5 + 0.1);
                this.sound.play("snd_goldcoin");
            } else {
                if (type == 3) {
                    this.score.Add(100 + this.level * 20 + 0.1);
                }
            }
        }
    };
    _r2.gameOver = function () {
        trace("게임오버");
        delete this.gogoon.onEnterFrame;
        delete this.rope.onEnterFrame;
        delete this.stage.onEnterFrame;
        this.sound.allStop();
        this.sound.play("snd_gameover");
        if (this.scope.bestscore < this.score.__get___num() || this.scope.bestscore == undefined) {
            this.scope.bestscore = this.score._num;
        }
        this.facetime.onStop();
        this.catstone.head_mc.gotoAndStop("smile");
        this.bitmapdata.dispose();
        this.bitmapdata2.dispose();
        _r2 = 0;
        while (_r2 < this.blockarr.length) {
            this.blockarr[_r2].body.gotoAndStop(2);
            _r2 = _r2 + 1;
        }
        this.mouse.__set___use(false);
        this.rope.clear();
        this.stick._visible = false;
        this.gogoon.gotoAndStop("die");
        _r3 = new OneTime();
        _r3.__set___time(0.3);
        _r3.onPlay = Delegate.create(this, this.gDown);
        _r3.onStart();
    };
    _r2.gDown = function () {
        _r2 = new mx.transitions.Tween(this.gogoon, "_y", mx.transitions.easing.Regular.easeIn, this.gogoon._y, this.gogoon._y + 250, 0.5, true);
        _r2.onMotionFinished = Delegate.create(this, this.gameoverPopup);
    };
    _r2.gameoverPopup = function () {
        this.onServerSend("gameover");
        _r2 = this.uistage.attachMovie("id_gameover", "gameover", 5, {_x: 230, _y: 50});
        _r2.btn_replay.onRelease = Delegate.create(this, this.reStart);
        var owner = this;
        _r2.btn_rank.onRollOver = _r0 = function () {
            owner.sound.play("snd_ropecatch");
        };
        _r2.btn_help.onRollOver = _r0 = _r0;
        _r2.btn_replay.onRollOver = _r0;
        _r2.btn_help.onRelease = function () {
            owner.onDestroy();
            owner.sound.play("snd_titlebg", 9999);
            owner.scope.gotoAndStop("help");
        };
        _r2.btn_rank.onRelease = function () {
            owner.sound.play("snd_btn");
            owner.onServerSend("viewrank");
        };
    };
    _r2.onDestroy = function () {
        this.catstone.head_mc.gotoAndStop("sleep");
        this.uistage.removeMovieClip();
        this.rope.removeMovieClip();
        this.gogoon.removeMovieClip();
        this.stage.removeMovieClip();
        this.itemstage.removeMovieClip();
    };
    _r2.reStart = function () {
        this.onDestroy();
        this.sound.play("snd_btn");
        this.scope.gotoAndStop("reset");
    };
    _r2.onServerSend = function (type) {
        trace("[플래시=>서버]" + type);
        if (type == "gamestart") {
            _global.ServerConnection.onGameStart();
        } else {
            if (type == "gameover") {
                _r4 = {score: this.score.__get___num()};
                _global.GAME = _r4;
                _global.ServerConnection.onGameOver(false);
            } else {
                if (type == "viewrank") {
                    _global.ServerConnection.popupVisible(true);
                }
            }
        }
    };
    _r2.onCounter = function () {
        var owner = this;
        _r2 = new LoadVars();
        _r2.onLoad = function (success) {
            if (success) {
                owner.scope.ranking_mc.count.text = this.count;
            }
        };
        _r2.sendAndLoad("http://jhworks.cafe24.com/count.php", _r2, "POST");
        trace("카운터");
    };
    _r2.onSaveScore = function () {
        _r2 = new LoadVars();
        _r2.onLoad = function (success) {
            if (success) {
            }
        };
        _r3 = this.scope.userid;
        _r2.sendAndLoad("http://211.110.89.169/flashgame/insertRank.php?gameid=fsagogun2&userid=" + _r3 + "&score=" + this.score.__get___num(), _r2, "POST");
    };
    _r2.onLoadScore = function () {
        var owner = this;
        _r2 = new LoadVars();
        _r2.onLoad = function (success) {
            if (success) {
                owner.onRank(this.userids, this.scores);
            }
        };
        _r2.sendAndLoad("http://211.110.89.169/flashgame/getTop10.php?gameid=fsagogun2", _r2, "POST");
    };
    _r2.onRank = function (userid, score) {
        _r4 = [];
        _r4 = score.split("|");
        _r3 = [];
        _r3 = userid.split("|");
        _r2 = 0;
        while (_r2 < 10) {
            if (_r3[_r2] != undefined) {
                this.scope.ranking_mc["userid" + _r2].text = _r3[_r2];
                this.scope.ranking_mc["score" + _r2].text = _r4[_r2];
            }
            _r2 = _r2 + 1;
        }
        this.best.__set___num(Number(_r4[0]));
        this.scope.bestscore = Number(_r4[0]);
    };
    _r2.onTestMap = function () {
        _r4 = this.scope.editor.maptxt.text;
        _r4 = _r4.split(" ").join("");
        _r4 = escape(_r4);
        _r3 = [];
        _r3 = _r4.split("%0D");
        _r2 = 0;
        while (_r2 < _r3.length) {
            _r4 = unescape(_r3[_r2]);
            _r3[_r2] = _r4.split(",");
            _r2 = _r2 + 1;
        }
        this.testmap = _r3;
        trace(this.testmap);
    };
    _r2.onTestItem = function () {
        _r4 = this.scope.editor.itemtxt.text;
        _r3 = [];
        _r4 = _r4.split(" ").join("");
        _r4 = escape(_r4);
        _r4 = _r4.split("%0D").join("");
        _r4 = unescape(_r4);
        _r4 = _r4.substr(1, _r4.length - 2);
        _r3 = _r4.split("],[");
        _r2 = 0;
        while (_r2 < _r3.length) {
            _r3[_r2] = _r3[_r2].split(",");
            _r2 = _r2 + 1;
        }
        this.testitem = _r3;
    };
    _r2.onTest = function (type) {
        this.speed = Number(this.scope.editor.speedtxt.text);
        if (type == "map") {
            this.test_map = true;
            this.onTestMap();
        }
        if (type == "item") {
            this.test_item = true;
            this.onTestItem();
        }
    };
    _r2.effectarr = [];
    _r2.way = 0;
    _r2.nextway = 0;
    _r2.count = 0;
    _r2.record = false;
    _r2.spacebar = false;
    _r2.test_map = false;
    _r2.test_item = false;
    _r2.testnum = 0;
    _r2.click = false;
    _r2.status = "run";
    _r2.depth = 100;
    _r2.speed = 15;
    _r2.addspeed = 1;
    _r2.level = 0;
    _r2.block_w = 150;
    _r2.dy = 30;
    _r2.gravity = 3.5;
    _r2.ground = 365;
    _r2.ropespeed = 40;
    _r2.maxcount = [50, 100, 150, 200, 250, 300, 1000];
}
ASSetPropFlags(_global.SetGame.prototype, null, 1);
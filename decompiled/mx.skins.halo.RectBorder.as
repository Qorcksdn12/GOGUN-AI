if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins) {
    _global.mx.skins = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins.halo) {
    _global.mx.skins.halo = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins.halo.RectBorder) {
    mx.skins.halo.RectBorder = _r1 = function () {
        super[undefined]();
    };
    mx.skins.halo.RectBorder.prototype = _r2 = new mx.skins.RectBorder();
    _r2.init = function (Void) {
        this.borderWidths.default = 3;
        super.init();
    };
    _r2.getBorderMetrics = function (Void) {
        if (this.offset == undefined) {
            _r3 = this.getStyle(this.borderStyleName);
            this.offset = this.borderWidths[_r3];
        }
        if (this.getStyle(this.borderStyleName) == "default" || this.getStyle(this.borderStyleName) == "alert") {
            this.__borderMetrics = {left: 3, top: 1, right: 3, bottom: 3};
            return this.__borderMetrics;
        }
        return super.getBorderMetrics();
    };
    _r2.drawBorder = function (Void) {
        _r6 = _global.styles[this.className];
        if (_r6 == undefined) {
            _r6 = _global.styles.RectBorder;
        }
        _r5 = this.getStyle(this.borderStyleName);
        _r7 = this.getStyle(this.borderColorName);
        if (_r7 == undefined) {
            _r7 = _r6[this.borderColorName];
        }
        _r8 = this.getStyle(this.backgroundColorName);
        if (_r8 == undefined) {
            _r8 = _r6[this.backgroundColorName];
        }
        _r16 = this.getStyle("backgroundImage");
        if (_r5 != "none") {
            _r14 = this.getStyle(this.shadowColorName);
            if (_r14 == undefined) {
                _r14 = _r6[this.shadowColorName];
            }
            _r13 = this.getStyle(this.highlightColorName);
            if (_r13 == undefined) {
                _r13 = _r6[this.highlightColorName];
            }
            _r12 = this.getStyle(this.buttonColorName);
            if (_r12 == undefined) {
                _r12 = _r6[this.buttonColorName];
            }
            _r11 = this.getStyle(this.borderCapColorName);
            if (_r11 == undefined) {
                _r11 = _r6[this.borderCapColorName];
            }
            _r10 = this.getStyle(this.shadowCapColorName);
            if (_r10 == undefined) {
                _r10 = _r6[this.shadowCapColorName];
            }
        }
        this.offset = this.borderWidths[_r5];
        _r9 = this.offset;
        _r3 = this.__get__width();
        _r4 = this.__get__height();
        this.clear();
        this._color = undefined;
        if (_r5 == "none") {
        } else {
            if (_r5 == "inset") {
                this._color = this.colorList;
                this.draw3dBorder(_r11, _r12, _r7, _r13, _r14, _r10);
            } else {
                if (_r5 == "outset") {
                    this._color = this.colorList;
                    this.draw3dBorder(_r11, _r7, _r12, _r14, _r13, _r10);
                } else {
                    if (_r5 == "alert") {
                        _r15 = this.getStyle("themeColor");
                        this.drawRoundRect(0, 5, _r3, _r4 - 5, 5, 6184542, 10);
                        this.drawRoundRect(1, 4, _r3 - 2, _r4 - 5, 4, [6184542, 6184542], 10, 0, "radial");
                        this.drawRoundRect(2, 0, _r3 - 4, _r4 - 2, 3, [0, 14342874], 100, 0, "radial");
                        this.drawRoundRect(2, 0, _r3 - 4, _r4 - 2, 3, _r15, 50);
                        this.drawRoundRect(3, 1, _r3 - 6, _r4 - 4, 2, 16777215, 100);
                    } else {
                        if (_r5 == "default") {
                            this.drawRoundRect(0, 5, _r3, _r4 - 5, {tl: 5, tr: 5, br: 0, bl: 0}, 6184542, 10);
                            this.drawRoundRect(1, 4, _r3 - 2, _r4 - 5, {tl: 4, tr: 4, br: 0, bl: 0}, [6184542, 6184542], 10, 0, "radial");
                            this.drawRoundRect(2, 0, _r3 - 4, _r4 - 2, {tl: 3, tr: 3, br: 0, bl: 0}, [12897484, 11844796], 100, 0, "radial");
                            this.drawRoundRect(3, 1, _r3 - 6, _r4 - 4, {tl: 2, tr: 2, br: 0, bl: 0}, 16777215, 100);
                        } else {
                            if (_r5 == "dropDown") {
                                this.drawRoundRect(0, 0, _r3 + 1, _r4, {tl: 4, tr: 0, br: 0, bl: 4}, [13290186, 7895160], 100, -10, "linear");
                                this.drawRoundRect(1, 1, _r3 - 1, _r4 - 2, {tl: 3, tr: 0, br: 0, bl: 3}, 16777215, 100);
                            } else {
                                if (_r5 == "menuBorder") {
                                    _r15 = this.getStyle("themeColor");
                                    this.drawRoundRect(4, 4, _r3 - 2, _r4 - 3, 0, [6184542, 6184542], 10, 0, "radial");
                                    this.drawRoundRect(4, 4, _r3 - 1, _r4 - 2, 0, 6184542, 10);
                                    this.drawRoundRect(0, 0, _r3 + 1, _r4, 0, [0, 14342874], 100, 250, "linear");
                                    this.drawRoundRect(0, 0, _r3 + 1, _r4, 0, _r15, 50);
                                    this.drawRoundRect(2, 2, _r3 - 3, _r4 - 4, 0, 16777215, 100);
                                } else {
                                    if (_r5 == "comboNonEdit") {
                                    } else {
                                        this.beginFill(_r7);
                                        this.drawRect(0, 0, _r3, _r4);
                                        this.drawRect(1, 1, _r3 - 1, _r4 - 1);
                                        this.endFill();
                                        this._color = this.borderColorName;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if (_r8 != undefined) {
            this.beginFill(_r8);
            this.drawRect(_r9, _r9, this.__get__width() - _r9, this.__get__height() - _r9);
            this.endFill();
        }
    };
    _r2.draw3dBorder = function (c1, c2, c3, c4, c5, c6) {
        _r3 = this.__get__width();
        _r2 = this.__get__height();
        this.beginFill(c1);
        this.drawRect(0, 0, _r3, _r2);
        this.drawRect(1, 0, _r3 - 1, _r2);
        this.endFill();
        this.beginFill(c2);
        this.drawRect(1, 0, _r3 - 1, 1);
        this.endFill();
        this.beginFill(c3);
        this.drawRect(1, _r2 - 1, _r3 - 1, _r2);
        this.endFill();
        this.beginFill(c4);
        this.drawRect(1, 1, _r3 - 1, 2);
        this.endFill();
        this.beginFill(c5);
        this.drawRect(1, _r2 - 2, _r3 - 1, _r2 - 1);
        this.endFill();
        this.beginFill(c6);
        this.drawRect(1, 2, _r3 - 1, _r2 - 2);
        this.drawRect(2, 2, _r3 - 2, _r2 - 2);
        this.endFill();
    };
    _r1.classConstruct = function () {
        mx.core.ext.UIObjectExtensions.Extensions();
        _global.styles.rectBorderClass = mx.skins.halo.RectBorder;
        _global.skinRegistry.RectBorder = true;
        return true;
    };
    _r1.symbolName = "RectBorder";
    _r1.symbolOwner = mx.skins.halo.RectBorder;
    _r1.version = "2.0.2.126";
    _r2.borderCapColorName = "borderCapColor";
    _r2.shadowCapColorName = "shadowCapColor";
    _r2.colorList = {highlightColor: 0, borderColor: 0, buttonColor: 0, shadowColor: 0, borderCapColor: 0, shadowCapColor: 0};
    _r2.borderWidths = {none: 0, solid: 1, inset: 2, outset: 2, alert: 3, dropDown: 2, menuBorder: 2, comboNonEdit: 2};
    _r1.classConstructed = mx.skins.halo.RectBorder.classConstruct();
    _r1.UIObjectExtensionsDependency = mx.core.ext.UIObjectExtensions;
}
ASSetPropFlags(mx.skins.halo.RectBorder.prototype, null, 1);
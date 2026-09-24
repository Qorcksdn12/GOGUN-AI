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
if (!_global.mx.skins.halo.ButtonSkin) {
    mx.skins.halo.ButtonSkin = _r1 = function () {
        super[undefined]();
    };
    mx.skins.halo.ButtonSkin.prototype = _r2 = new mx.skins.RectBorder();
    _r2.init = function () {
        super.init();
    };
    _r2.size = function () {
        this.drawHaloRect(this.__get__width(), this.__get__height());
    };
    _r2.drawHaloRect = function (w, h) {
        _r6 = this.getStyle("borderStyle");
        _r4 = this.getStyle("themeColor");
        _r5 = this._parent.emphasized;
        this.clear();
        if ((_r0 = _r6) !== "falseup") {
            if (_r0 === "falsedown") goto L1256;
            if (_r0 === "falserollover") goto L1955;
            if (_r0 === "falsedisabled") goto L2657;
            if (_r0 === "trueup") goto L2896;
            if (_r0 === "truedown") goto L3598;
            if (_r0 === "truerollover") goto L4297;
            if (_r0 === "truedisabled") goto L5099;
        } else {
            if (_r5) {
                this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, 9542041, 100);
                this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, _r4, 75);
                this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, [3355443, 16777215], 85, 0, "radial");
                this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, [0, 14342874], 100, 0, "radial");
                this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, _r4, 75);
                this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 3, w - 6, h - 6, 2, 16777215, 100);
                this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 4, w - 6, h - 7, 2, 16316664, 100);
            } else {
                this.drawRoundRect(0, 0, w, h, 5, 9542041, 100);
                this.drawRoundRect(1, 1, w - 2, h - 2, 4, [13291985, 16250871], 100, 0, "radial");
                this.drawRoundRect(2, 2, w - 4, h - 4, 3, [9542041, 13818586], 100, 0, "radial");
                this.drawRoundRect(3, 3, w - 6, h - 6, 2, 16777215, 100);
                this.drawRoundRect(3, 4, w - 6, h - 7, 2, 16316664, 100);
            }
            return; /*jump end*/
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, 9542041, 100);
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, [3355443, 16579836], 100, 0, "radial");
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, _r4, 50);
            this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, [0, 14342874], 100, 0, "radial");
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, _r4, 40);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 3, w - 6, h - 6, 2, 16777215, 100);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 4, w - 6, h - 7, 2, _r4, 20);
            return; /*jump end*/
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, 9542041, 100);
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, _r4, 50);
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, [3355443, 16777215], 100, 0, "radial");
            this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, [0, 14342874], 100, 0, "radial");
            this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, _r4, 50);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 3, w - 6, h - 6, 2, 16777215, 100);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 4, w - 6, h - 7, 2, 16316664, 100);
            return; /*jump end*/
            this.drawRoundRect(0, 0, w, h, 5, 13159628, 100);
            this.drawRoundRect(1, 1, w - 2, h - 2, 4, 15921906, 100);
            this.drawRoundRect(2, 2, w - 4, h - 4, 3, 13949401, 100);
            this.drawRoundRect(3, 3, w - 6, h - 6, 2, 15921906, 100);
            return; /*jump end*/
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, 10066329, 100);
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, [3355443, 16579836], 100, 0, "radial");
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, _r4, 50);
            this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, [0, 14342874], 100, 0, "radial");
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, _r4, 40);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 3, w - 6, h - 6, 2, 16777215, 100);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 4, w - 6, h - 7, 2, 16250871, 100);
            return; /*jump end*/
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, 10066329, 100);
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, [3355443, 16579836], 100, 0, "radial");
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, _r4, 50);
            this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, [0, 14342874], 100, 0, "radial");
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, _r4, 40);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 3, w - 6, h - 6, 2, 16777215, 100);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 4, w - 6, h - 7, 2, _r4, 20);
            return; /*jump end*/
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, 9542041, 100);
            this.drawRoundRect(this.__get__x(), this.__get__y(), w, h, 5, _r4, 50);
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, [3355443, 16777215], 100, 0, "radial");
            this.drawRoundRect(this.__get__x() + 1, this.__get__y() + 1, w - 2, h - 2, 4, _r4, 40);
            this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, [0, 14342874], 100, 0, "radial");
            this.drawRoundRect(this.__get__x() + 2, this.__get__y() + 2, w - 4, h - 4, 3, _r4, 40);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 3, w - 6, h - 6, 2, 16777215, 100);
            this.drawRoundRect(this.__get__x() + 3, this.__get__y() + 4, w - 6, h - 7, 2, 16316664, 100);
            return; /*jump end*/
            this.drawRoundRect(0, 0, w, h, 5, 13159628, 100);
            this.drawRoundRect(1, 1, w - 2, h - 2, 4, 15921906, 100);
            this.drawRoundRect(2, 2, w - 4, h - 4, 3, 13949401, 100);
            this.drawRoundRect(3, 3, w - 6, h - 6, 2, 15921906, 100);
        }
    };
    _r1.classConstruct = function () {
        mx.core.ext.UIObjectExtensions.Extensions();
        _global.skinRegistry.ButtonSkin = true;
        return true;
    };
    _r1.symbolName = "ButtonSkin";
    _r1.symbolOwner = mx.skins.halo.ButtonSkin;
    _r2.className = "ButtonSkin";
    _r2.backgroundColorName = "buttonColor";
    _r1.classConstructed = mx.skins.halo.ButtonSkin.classConstruct();
    _r1.UIObjectExtensionsDependency = mx.core.ext.UIObjectExtensions;
}
ASSetPropFlags(mx.skins.halo.ButtonSkin.prototype, null, 1);
if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins) {
    _global.mx.skins = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins.ColoredSkinElement) {
    mx.skins.ColoredSkinElement = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r2.setColor = function (c) {
        if (c != undefined) {
            _r2 = new Color(this);
            _r2.setRGB(c);
        }
    };
    _r2.draw = function (Void) {
        this.setColor(this.getStyle(this._color));
        this.onEnterFrame = undefined;
    };
    _r2.invalidateStyle = function (Void) {
        this.onEnterFrame = this.draw;
    };
    _r1.setColorStyle = function (p, colorStyle) {
        if (p._color == undefined) {
            p._color = colorStyle;
        }
        p.setColor = mx.skins.ColoredSkinElement.mixins.setColor;
        p.invalidateStyle = mx.skins.ColoredSkinElement.mixins.invalidateStyle;
        p.draw = mx.skins.ColoredSkinElement.mixins.draw;
        p.setColor(p.getStyle(colorStyle));
    };
    _r1.mixins = new mx.skins.ColoredSkinElement();
}
ASSetPropFlags(mx.skins.ColoredSkinElement.prototype, null, 1);
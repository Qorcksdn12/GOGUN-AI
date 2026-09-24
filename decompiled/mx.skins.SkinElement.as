if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins) {
    _global.mx.skins = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins.SkinElement) {
    mx.skins.SkinElement = _r1 = function () {
        super[undefined]();
    };
    mx.skins.SkinElement.prototype = _r2 = new MovieClip();
    _r1.registerElement = function (name, className) {
        Object.registerClass(name, className != undefined ? className : mx.skins.SkinElement);
        _global.skinRegistry[name] = true;
    };
    _r2.__set__visible = function (visible) {
        this._visible = visible;
    };
    _r2.move = function (x, y) {
        this._x = x;
        this._y = y;
    };
    _r2.setSize = function (w, h) {
        this._width = w;
        this._height = h;
    };
}
ASSetPropFlags(mx.skins.SkinElement.prototype, null, 1);
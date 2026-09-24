if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins) {
    _global.mx.skins = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins.RectBorder) {
    mx.skins.RectBorder = _r1 = function () {
        super[undefined]();
    };
    mx.skins.RectBorder.prototype = _r2 = new mx.skins.Border();
    _r2.__get__width = function () {
        return this.__width;
    };
    _r2.__get__height = function () {
        return this.__height;
    };
    _r2.init = function (Void) {
        super.init();
    };
    _r2.draw = function (Void) {
        this.size();
    };
    _r2.getBorderMetrics = function (Void) {
        _r2 = this.offset;
        if (this.__borderMetrics == undefined) {
            this.__borderMetrics = {left: _r2, top: _r2, right: _r2, bottom: _r2};
        } else {
            this.__borderMetrics.left = _r2;
            this.__borderMetrics.top = _r2;
            this.__borderMetrics.right = _r2;
            this.__borderMetrics.bottom = _r2;
        }
        return this.__borderMetrics;
    };
    _r2.__get__borderMetrics = function () {
        return this.getBorderMetrics();
    };
    _r2.drawBorder = function (Void) {
    };
    _r2.size = function (Void) {
        this.drawBorder();
    };
    _r2.setColor = function (Void) {
        this.drawBorder();
    };
    _r1.symbolName = "RectBorder";
    _r1.symbolOwner = mx.skins.RectBorder;
    _r1.version = "2.0.2.126";
    _r2.className = "RectBorder";
    _r2.borderStyleName = "borderStyle";
    _r2.borderColorName = "borderColor";
    _r2.shadowColorName = "shadowColor";
    _r2.highlightColorName = "highlightColor";
    _r2.buttonColorName = "buttonColor";
    _r2.backgroundColorName = "backgroundColor";
}
ASSetPropFlags(mx.skins.RectBorder.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("borderMetrics", _r2.__get__borderMetrics, function () {\n})', '_r2.addProperty("height", _r2.__get__height, function () {\n})', '_r2.addProperty("width", _r2.__get__width, function () {\n})'] */
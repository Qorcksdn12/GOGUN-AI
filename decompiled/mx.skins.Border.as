if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins) {
    _global.mx.skins = new Object();
}
<UNDERFLOW>;
if (!_global.mx.skins.Border) {
    mx.skins.Border = _r1 = function () {
        super[undefined]();
    };
    mx.skins.Border.prototype = _r2 = new mx.core.UIObject();
    _r2.init = function (Void) {
        super.init();
    };
    _r1.symbolName = "Border";
    _r1.symbolOwner = mx.skins.Border;
    _r2.className = "Border";
    _r2.tagBorder = 0;
    _r2.idNames = new Array("border_mc");
}
ASSetPropFlags(mx.skins.Border.prototype, null, 1);
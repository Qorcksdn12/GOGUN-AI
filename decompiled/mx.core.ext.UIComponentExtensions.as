if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.core) {
    _global.mx.core = new Object();
}
<UNDERFLOW>;
if (!_global.mx.core.ext) {
    _global.mx.core.ext = new Object();
}
<UNDERFLOW>;
if (!_global.mx.core.ext.UIComponentExtensions) {
    mx.core.ext.UIComponentExtensions = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.Extensions = function () {
        if (mx.core.ext.UIComponentExtensions.bExtended == true) {
            return true;
        }
        mx.core.ext.UIComponentExtensions.bExtended = true;
        TextField.prototype.setFocus = function () {
            Selection.setFocus(this);
        };
        TextField.prototype.onSetFocus = function (oldFocus) {
            if (this.tabEnabled != false) {
                if (this.getFocusManager().bDrawFocus) {
                    this.drawFocus(true);
                }
            }
        };
        TextField.prototype.onKillFocus = function (oldFocus) {
            if (this.tabEnabled != false) {
                this.drawFocus(false);
            }
        };
        TextField.prototype.drawFocus = mx.core.UIComponent.prototype.drawFocus;
        TextField.prototype.getFocusManager = mx.core.UIComponent.prototype.getFocusManager;
        mx.managers.OverlappedWindows.enableOverlappedWindows();
        mx.styles.CSSSetStyle.enableRunTimeCSS();
        mx.managers.FocusManager.enableFocusManagement();
    };
    _r1.bExtended = false;
    _r1.UIComponentExtended = mx.core.ext.UIComponentExtensions.Extensions();
    _r1.UIComponentDependency = mx.core.UIComponent;
    _r1.FocusManagerDependency = mx.managers.FocusManager;
    _r1.OverlappedWindowsDependency = mx.managers.OverlappedWindows;
}
ASSetPropFlags(mx.core.ext.UIComponentExtensions.prototype, null, 1);
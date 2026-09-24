if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.core) {
    _global.mx.core = new Object();
}
<UNDERFLOW>;
if (!_global.mx.core.UIComponent) {
    mx.core.UIComponent = _r1 = function () {
        super[undefined]();
    };
    mx.core.UIComponent.prototype = _r2 = new mx.core.UIObject();
    _r2.__get__width = function () {
        return this.__width;
    };
    _r2.__get__height = function () {
        return this.__height;
    };
    _r2.setVisible = function (x, noEvent) {
        super.setVisible(x, noEvent);
    };
    _r2.enabledChanged = function (id, oldValue, newValue) {
        this.setEnabled(newValue);
        this.invalidate();
        delete this.stylecache.tf;
        return newValue;
    };
    _r2.setEnabled = function (enabled) {
        this.invalidate();
    };
    _r2.getFocus = function () {
        var selFocus = Selection.getFocus();
        return selFocus !== null ? eval(selFocus) : null;
    };
    _r2.setFocus = function () {
        Selection.setFocus(this);
    };
    _r2.getFocusManager = function () {
        _r2 = this;
        while (_r2 != undefined) {
            if (_r2.focusManager != undefined) {
                return _r2.focusManager;
            }
            _r2 = _r2._parent;
        }
        return undefined;
    };
    _r2.onKillFocus = function (newFocus) {
        this.removeEventListener("keyDown", this);
        this.removeEventListener("keyUp", this);
        this.dispatchEvent({type: "focusOut"});
        this.drawFocus(false);
    };
    _r2.onSetFocus = function (oldFocus) {
        this.addEventListener("keyDown", this);
        this.addEventListener("keyUp", this);
        this.dispatchEvent({type: "focusIn"});
        if (this.getFocusManager().bDrawFocus != false) {
            this.drawFocus(true);
        }
    };
    _r2.findFocusInChildren = function (o) {
        if (o.focusTextField != undefined) {
            return o.focusTextField;
        }
        if (o.tabEnabled == true) {
            return o;
        }
        return undefined;
    };
    _r2.findFocusFromObject = function (o) {
        if (o.tabEnabled != true) {
            if (o._parent == undefined) {
                return undefined;
            }
            if (o._parent.tabEnabled == true) {
                o = o._parent;
            } else {
                if (o._parent.tabChildren) {
                    o = this.findFocusInChildren(o._parent);
                } else {
                    o = this.findFocusFromObject(o._parent);
                }
            }
        }
        return o;
    };
    _r2.pressFocus = function () {
        _r3 = this.findFocusFromObject(this);
        _r2 = this.getFocus();
        if (_r3 != _r2) {
            _r2.drawFocus(false);
            if (this.getFocusManager().bDrawFocus != false) {
                _r3.drawFocus(true);
            }
        }
    };
    _r2.releaseFocus = function () {
        _r2 = this.findFocusFromObject(this);
        if (_r2 != this.getFocus()) {
            _r2.setFocus();
        }
    };
    _r2.isParent = function (o) {
        while (o != undefined) {
            if (o == this) {
                return true;
            }
            o = o._parent;
        }
        return false;
    };
    _r2.size = function () {
    };
    _r2.init = function () {
        super.init();
        this._xscale = 100;
        this._yscale = 100;
        this._focusrect = _global.useFocusRect == false;
        this.watch("enabled", this.enabledChanged);
        if (this.enabled == false) {
            this.setEnabled(false);
        }
    };
    _r2.dispatchValueChangedEvent = function (value) {
        this.dispatchEvent({type: "valueChanged", value: value});
    };
    _r1.symbolName = "UIComponent";
    _r1.symbolOwner = mx.core.UIComponent;
    _r1.version = "2.0.2.126";
    _r1.kStretch = 5000;
    _r2.focusEnabled = true;
    _r2.tabEnabled = true;
    _r2.origBorderStyles = {themeColor: 16711680};
    _r2.clipParameters = {};
    _r1.mergedClipParameters = mx.core.UIObject.mergeClipParameters(mx.core.UIComponent.prototype.clipParameters, mx.core.UIObject.prototype.clipParameters);
}
ASSetPropFlags(mx.core.UIComponent.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("height", _r2.__get__height, function () {\n})', '_r2.addProperty("width", _r2.__get__width, function () {\n})'] */
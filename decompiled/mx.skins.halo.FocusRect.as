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
if (!_global.mx.skins.halo.FocusRect) {
    mx.skins.halo.FocusRect = _r1 = function () {
        super[undefined]();
        this.boundingBox_mc._visible = false;
        this.boundingBox_mc._height = _r0 = 0;
        this.boundingBox_mc._width = _r0;
    };
    mx.skins.halo.FocusRect.prototype = _r2 = new mx.skins.SkinElement();
    _r2.draw = function (o) {
        o.adjustFocusRect();
    };
    _r2.setSize = function (w, h, r, a, rectCol) {
        this._yscale = _r0 = 100;
        this._xscale = _r0;
        this.clear();
        if (typeof r == "object") {
            r.br = r.br <= 2 ? 0 : r.br - 2;
            r.bl = r.bl <= 2 ? 0 : r.bl - 2;
            r.tr = r.tr <= 2 ? 0 : r.tr - 2;
            r.tl = r.tl <= 2 ? 0 : r.tl - 2;
            this.beginFill(rectCol, a * 0.3);
            this.drawRoundRect(0, 0, w, h, r);
            this.drawRoundRect(2, 2, w - 4, h - 4, r);
            this.endFill();
            r.br = r.br <= 1 ? 0 : r.br + 1;
            r.bl = r.bl <= 1 ? 0 : r.bl + 1;
            r.tr = r.tr <= 1 ? 0 : r.tr + 1;
            r.tl = r.tl <= 1 ? 0 : r.tl + 1;
            this.beginFill(rectCol, a * 0.3);
            this.drawRoundRect(1, 1, w - 2, h - 2, r);
            r.br = r.br <= 1 ? 0 : r.br - 1;
            r.bl = r.bl <= 1 ? 0 : r.bl - 1;
            r.tr = r.tr <= 1 ? 0 : r.tr - 1;
            r.tl = r.tl <= 1 ? 0 : r.tl - 1;
            this.drawRoundRect(2, 2, w - 4, h - 4, r);
            this.endFill();
        } else {
            _r5 = undefined;
            if (r != 0) {
                _r5 = r - 2;
            } else {
                _r5 = 0;
            }
            this.beginFill(rectCol, a * 0.3);
            this.drawRoundRect(0, 0, w, h, r);
            this.drawRoundRect(2, 2, w - 4, h - 4, _r5);
            this.endFill();
            this.beginFill(rectCol, a * 0.3);
            if (r != 0) {
                _r5 = r - 2;
                r = r - 1;
            } else {
                _r5 = 0;
                r = 0;
            }
            this.drawRoundRect(1, 1, w - 2, h - 2, r);
            this.drawRoundRect(2, 2, w - 4, h - 4, _r5);
            this.endFill();
        }
    };
    _r2.handleEvent = function (e) {
        if (e.type == "unload") {
            this._visible = true;
        } else {
            if (e.type == "resize") {
                e.target.adjustFocusRect();
            } else {
                if (e.type == "move") {
                    e.target.adjustFocusRect();
                }
            }
        }
    };
    _r1.classConstruct = function () {
        mx.core.UIComponent.prototype.drawFocus = function (focused) {
            _r2 = this._parent.focus_mc;
            if (!focused) {
                _r2._visible = false;
                this.removeEventListener("unload", _r2);
                this.removeEventListener("move", _r2);
                this.removeEventListener("resize", _r2);
            } else {
                if (_r2 == undefined) {
                    _r2 = this._parent.createChildAtDepth("FocusRect", mx.managers.DepthManager.kTop);
                    _r2.tabEnabled = false;
                    this._parent.focus_mc = _r2;
                } else {
                    _r2._visible = true;
                }
                _r2.draw(this);
                if (_r2.getDepth() < this.getDepth()) {
                    _r2.setDepthAbove(this);
                }
                this.addEventListener("unload", _r2);
                this.addEventListener("move", _r2);
                this.addEventListener("resize", _r2);
            }
        };
        mx.core.UIComponent.prototype.adjustFocusRect = function () {
            _r2 = this.getStyle("themeColor");
            if (_r2 == undefined) {
                _r2 = 8453965;
            }
            _r3 = this._parent.focus_mc;
            _r3.setSize(this.width + 4, this.height + 4, 0, 100, _r2);
            _r3.move(this.x - 2, this.y - 2);
        };
        TextField.prototype.drawFocus = mx.core.UIComponent.prototype.drawFocus;
        TextField.prototype.adjustFocusRect = mx.core.UIComponent.prototype.adjustFocusRect;
        mx.skins.halo.FocusRect.prototype.drawRoundRect = mx.skins.halo.Defaults.prototype.drawRoundRect;
        return true;
    };
    _r1.classConstructed = mx.skins.halo.FocusRect.classConstruct();
    _r1.DefaultsDependency = mx.skins.halo.Defaults;
    _r1.UIComponentDependency = mx.core.UIComponent;
}
ASSetPropFlags(mx.skins.halo.FocusRect.prototype, null, 1);
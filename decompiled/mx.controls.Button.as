if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.controls) {
    _global.mx.controls = new Object();
}
<UNDERFLOW>;
if (!_global.mx.controls.Button) {
    mx.controls.Button = _r1 = function () {
        super[undefined]();
    };
    mx.controls.Button.prototype = _r2 = new mx.controls.SimpleButton();
    _r2.init = function (Void) {
        super.init();
    };
    _r2.draw = function () {
        if (this.initializing) {
            this.labelPath.visible = true;
        }
        super.draw();
        if (this.initIcon != undefined) {
            this._setIcon(this.initIcon);
        }
        delete this.initIcon;
    };
    _r2.onRelease = function (Void) {
        super.onRelease();
    };
    _r2.createChildren = function (Void) {
        super.createChildren();
    };
    _r2.setSkin = function (tag, linkageName, initobj) {
        return super.setSkin(tag, linkageName, initobj);
    };
    _r2.viewSkin = function (varName) {
        _r3 = !this.getState() ? "false" : "true";
        _r3 = _r3 + (!this.enabled ? "disabled" : this.phase);
        super.viewSkin(varName, {styleName: this, borderStyle: _r3});
    };
    _r2.invalidateStyle = function (c) {
        this.labelPath.invalidateStyle(c);
        super.invalidateStyle(c);
    };
    _r2.setColor = function (c) {
        _r2 = 0;
        while (_r2 < 8) {
            this[this.idNames[_r2]].redraw(true);
            _r2 = _r2 + 1;
        }
    };
    _r2.setEnabled = function (enable) {
        this.labelPath.enabled = enable;
        super.setEnabled(enable);
    };
    _r2.calcSize = function (tag, ref) {
        if (this.__width == undefined || this.__height == undefined) {
            return undefined;
        }
        if (tag < 7) {
            ref.setSize(this.__width, this.__height, true);
        }
    };
    _r2.size = function (Void) {
        this.setState(this.getState());
        this.setHitArea(this.__width, this.__height);
        _r3 = 0;
        while (_r3 < 8) {
            _r4 = this.idNames[_r3];
            if (typeof this[_r4] == "movieclip") {
                this[_r4].setSize(this.__width, this.__height, true);
            }
            _r3 = _r3 + 1;
        }
        super.size();
    };
    _r2.__set__labelPlacement = function (val) {
        this.__labelPlacement = val;
        this.invalidate();
        return this.__get__labelPlacement();
        <UNDERFLOW>;
    };
    _r2.__get__labelPlacement = function () {
        return this.__labelPlacement;
    };
    _r2.getLabelPlacement = function (Void) {
        return this.__labelPlacement;
    };
    _r2.setLabelPlacement = function (val) {
        this.__labelPlacement = val;
        this.invalidate();
    };
    _r2.getBtnOffset = function (Void) {
        if (this.getState()) {
            _r2 = this.btnOffset;
        } else {
            if (this.phase == "down") {
                _r2 = this.btnOffset;
            } else {
                _r2 = 0;
            }
        }
        return _r2;
    };
    _r2.setView = function (offset) {
        _r16 = !offset ? 0 : this.btnOffset;
        _r12 = this.getLabelPlacement();
        _r7 = 0;
        _r6 = 0;
        _r9 = 0;
        _r8 = 0;
        _r5 = 0;
        _r4 = 0;
        _r3 = this.labelPath;
        _r2 = this.iconName;
        _r15 = _r3.textWidth;
        _r14 = _r3.textHeight;
        _r10 = this.__width - this.borderW - this.borderW;
        _r11 = this.__height - this.borderW - this.borderW;
        if (_r2 != undefined) {
            _r7 = _r2._width;
            _r6 = _r2._height;
        }
        if (_r12 == "left" || _r12 == "right") {
            if (_r3 != undefined) {
                _r3._width = _r9 = Math.min(_r10 - _r7, _r15 + 5);
                _r3._height = _r8 = Math.min(_r11, _r14 + 5);
            }
            if (_r12 == "right") {
                _r5 = _r7;
                if (this.centerContent) {
                    _r5 = _r5 + (_r10 - _r9 - _r7) / 2;
                }
                _r2._x = _r5 - _r7;
            } else {
                _r5 = _r10 - _r9 - _r7;
                if (this.centerContent) {
                    _r5 = _r5 / 2;
                }
                _r2._x = _r5 + _r9;
            }
            _r2._y = _r4 = 0;
            if (this.centerContent) {
                _r2._y = (_r11 - _r6) / 2;
                _r4 = (_r11 - _r8) / 2;
            }
            if (!this.centerContent) {
                _r2._y = _r2._y + Math.max(0, (_r8 - _r6) / 2);
            }
        } else {
            if (_r3 != undefined) {
                _r3._width = _r9 = Math.min(_r10, _r15 + 5);
                _r3._height = _r8 = Math.min(_r11 - _r6, _r14 + 5);
            }
            _r5 = (_r10 - _r9) / 2;
            _r2._x = (_r10 - _r7) / 2;
            if (_r12 == "top") {
                _r4 = _r11 - _r8 - _r6;
                if (this.centerContent) {
                    _r4 = _r4 / 2;
                }
                _r2._y = _r4 + _r8;
            } else {
                _r4 = _r6;
                if (this.centerContent) {
                    _r4 = _r4 + (_r11 - _r8 - _r6) / 2;
                }
                _r2._y = _r4 - _r6;
            }
        }
        _r13 = this.borderW + _r16;
        _r3._x = _r5 + _r13;
        _r3._y = _r4 + _r13;
        _r2._x = _r2._x + _r13;
        _r2._y = _r2._y + _r13;
    };
    _r2.__set__label = function (lbl) {
        this.setLabel(lbl);
        return this.__get__label();
        <UNDERFLOW>;
    };
    _r2.setLabel = function (label) {
        if (label == "") {
            this.labelPath.removeTextField();
            this.refresh();
            return undefined;
        }
        if (this.labelPath == undefined) {
            _r2 = this.createLabel("labelPath", 200, label);
            _r2._width = _r2.textWidth + 5;
            _r2._height = _r2.textHeight + 5;
            if (this.initializing) {
                _r2.visible = false;
            }
        } else {
            delete this.labelPath.__text;
            this.labelPath.text = label;
            this.refresh();
        }
    };
    _r2.getLabel = function (Void) {
        return this.labelPath.__text == undefined ? this.labelPath.text : this.labelPath.__text;
    };
    _r2.__get__label = function () {
        return this.getLabel();
    };
    _r2._getIcon = function (Void) {
        return this._iconLinkageName;
    };
    _r2.__get__icon = function () {
        if (this.initializing) {
            return this.initIcon;
        }
        return this._iconLinkageName;
    };
    _r2._setIcon = function (linkage) {
        if (this.initializing) {
            if (linkage == "") {
                return undefined;
            }
            this.initIcon = linkage;
        } else {
            if (linkage == "") {
                this.removeIcons();
                return undefined;
            }
            super.changeIcon(0, linkage);
            super.changeIcon(1, linkage);
            super.changeIcon(3, linkage);
            super.changeIcon(4, linkage);
            super.changeIcon(5, linkage);
            this._iconLinkageName = linkage;
            this.refresh();
        }
    };
    _r2.__set__icon = function (linkage) {
        this._setIcon(linkage);
        return this.__get__icon();
        <UNDERFLOW>;
    };
    _r2.setHitArea = function (w, h) {
        if (this.hitArea_mc == undefined) {
            this.createEmptyObject("hitArea_mc", 100);
        }
        _r2 = this.hitArea_mc;
        _r2.clear();
        _r2.beginFill(16711680);
        _r2.drawRect(0, 0, w, h);
        _r2.endFill();
        _r2.setVisible(false);
    };
    _r1.symbolName = "Button";
    _r1.symbolOwner = mx.controls.Button;
    _r2.className = "Button";
    _r1.version = "2.0.2.126";
    _r2.btnOffset = 0;
    _r2._color = "buttonColor";
    _r2.__label = "default value";
    _r2.__labelPlacement = "right";
    _r2.falseUpSkin = "ButtonSkin";
    _r2.falseDownSkin = "ButtonSkin";
    _r2.falseOverSkin = "ButtonSkin";
    _r2.falseDisabledSkin = "ButtonSkin";
    _r2.trueUpSkin = "ButtonSkin";
    _r2.trueDownSkin = "ButtonSkin";
    _r2.trueOverSkin = "ButtonSkin";
    _r2.trueDisabledSkin = "ButtonSkin";
    _r2.falseUpIcon = "";
    _r2.falseDownIcon = "";
    _r2.falseOverIcon = "";
    _r2.falseDisabledIcon = "";
    _r2.trueUpIcon = "";
    _r2.trueDownIcon = "";
    _r2.trueOverIcon = "";
    _r2.trueDisabledIcon = "";
    _r2.clipParameters = {labelPlacement: 1, icon: 1, toggle: 1, selected: 1, label: 1};
    _r1.mergedClipParameters = mx.core.UIObject.mergeClipParameters(mx.controls.Button.prototype.clipParameters, mx.controls.SimpleButton.prototype.clipParameters);
    _r2.centerContent = true;
    _r2.borderW = 1;
}
ASSetPropFlags(mx.controls.Button.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("icon", _r2.__get__icon, _r2.__set__icon)', '_r2.addProperty("label", _r2.__get__label, _r2.__set__label)', '_r2.addProperty("labelPlacement", _r2.__get__labelPlacement, _r2.__set__labelPlacement)'] */
if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.controls) {
    _global.mx.controls = new Object();
}
<UNDERFLOW>;
if (!_global.mx.controls.SimpleButton) {
    mx.controls.SimpleButton = _r1 = function () {
        super[undefined]();
    };
    mx.controls.SimpleButton.prototype = _r2 = new mx.core.UIComponent();
    _r2.init = function (Void) {
        super.init();
        if (this.preset == undefined) {
            this.boundingBox_mc._visible = false;
            this.boundingBox_mc._height = _r0 = 0;
            this.boundingBox_mc._width = _r0;
        }
        this.useHandCursor = false;
    };
    _r2.createChildren = function (Void) {
        if (this.preset != undefined) {
            _r2 = this[this.idNames[this.preset]];
            this[this.refNames[this.preset]] = _r2;
            this.skinName = _r2;
            if (this.falseOverSkin.length == 0) {
                this.rolloverSkin = this.fus;
            }
            if (this.falseOverIcon.length == 0) {
                this.rolloverIcon = this.fui;
            }
            this.initializing = false;
        } else {
            if (this.__state == true) {
                this.setStateVar(true);
            } else {
                if (this.falseOverSkin.length == 0) {
                    this.rolloverSkin = this.fus;
                }
                if (this.falseOverIcon.length == 0) {
                    this.rolloverIcon = this.fui;
                }
            }
        }
    };
    _r2.setIcon = function (tag, linkageName) {
        return this.setSkin(tag + 8, linkageName);
    };
    _r2.changeIcon = function (tag, linkageName) {
        this.linkLength = linkageName.length;
        _r2 = this.stateNames[tag] + "Icon";
        this[_r2] = linkageName;
        this[this.idNames[tag + 8]] = _r2;
        this.setStateVar(this.getState());
    };
    _r2.changeSkin = function (tag, linkageName) {
        _r2 = this.stateNames[tag] + "Skin";
        this[_r2] = linkageName;
        this[this.idNames[tag]] = _r2;
        this.setStateVar(this.getState());
    };
    _r2.viewIcon = function (varName) {
        _r4 = varName + "Icon";
        _r3 = this[_r4];
        if (typeof _r3 == "string") {
            _r5 = _r3;
            if (this.__emphasized) {
                if (this[_r3 + "Emphasized"].length > 0) {
                    _r3 = _r3 + "Emphasized";
                }
            }
            if (this[_r3].length == 0) {
                return undefined;
            }
            _r3 = this.setIcon(this.tagMap[_r5], this[_r3]);
            if (_r3 == undefined && _global.isLivePreview) {
                _r3 = this.setIcon(0, "ButtonIcon");
            }
            this[_r4] = _r3;
        }
        this.iconName._visible = false;
        this.iconName = _r3;
        this.iconName._visible = true;
    };
    _r2.removeIcons = function () {
        _r3 = 0;
        while (_r3 < 2) {
            _r2 = 8;
            while (_r2 < 16) {
                this.destroyObject(this.idNames[_r2]);
                this[this.stateNames[_r2 - 8] + "Icon"] = "";
                _r2 = _r2 + 1;
            }
            _r3 = _r3 + 1;
        }
        this.refresh();
    };
    _r2.setSkin = function (tag, linkageName, initobj) {
        _r3 = super.setSkin(tag, linkageName, initobj == undefined ? {styleName: this} : initobj);
        this.calcSize(tag, _r3);
        return _r3;
    };
    _r2.calcSize = function (Void) {
        this.__width = this._width;
        this.__height = this._height;
    };
    _r2.viewSkin = function (varName, initObj) {
        _r3 = varName + "Skin";
        _r2 = this[_r3];
        if (typeof _r2 == "string") {
            _r4 = _r2;
            if (this.__emphasized) {
                if (this[_r2 + "Emphasized"].length > 0) {
                    _r2 = _r2 + "Emphasized";
                }
            }
            if (this[_r2].length == 0) {
                return undefined;
            }
            _r2 = this.setSkin(this.tagMap[_r4], this[_r2], initObj == undefined ? {styleName: this} : initObj);
            this[_r3] = _r2;
        }
        this.skinName._visible = false;
        this.skinName = _r2;
        this.skinName._visible = true;
    };
    _r2.showEmphasized = function (e) {
        if (e && !this.__emphatic) {
            if (mx.controls.SimpleButton.emphasizedStyleDeclaration != undefined) {
                this.__emphaticStyleName = this.styleName;
                this.styleName = mx.controls.SimpleButton.emphasizedStyleDeclaration;
            }
            this.__emphatic = true;
        } else {
            if (this.__emphatic) {
                this.styleName = this.__emphaticStyleName;
            }
            this.__emphatic = false;
        }
    };
    _r2.refresh = function (Void) {
        _r2 = this.getState();
        if (this.enabled == false) {
            this.viewIcon("disabled");
            this.viewSkin("disabled");
        } else {
            this.viewSkin(this.phase);
            this.viewIcon(this.phase);
        }
        this.setView(this.phase == "down");
        this.iconName.enabled = this.enabled;
    };
    _r2.setView = function (offset) {
        if (this.iconName == undefined) {
            return undefined;
        }
        _r2 = !offset ? 0 : this.btnOffset;
        this.iconName._x = (this.__width - this.iconName._width) / 2 + _r2;
        this.iconName._y = (this.__height - this.iconName._height) / 2 + _r2;
    };
    _r2.setStateVar = function (state) {
        if (state) {
            if (this.trueOverSkin.length == 0) {
                this.rolloverSkin = this.tus;
            } else {
                this.rolloverSkin = this.trs;
            }
            if (this.trueOverIcon.length == 0) {
                this.rolloverIcon = this.tui;
            } else {
                this.rolloverIcon = this.tri;
            }
            this.upSkin = this.tus;
            this.downSkin = this.tds;
            this.disabledSkin = this.dts;
            this.upIcon = this.tui;
            this.downIcon = this.tdi;
            this.disabledIcon = this.dti;
        } else {
            if (this.falseOverSkin.length == 0) {
                this.rolloverSkin = this.fus;
            } else {
                this.rolloverSkin = this.frs;
            }
            if (this.falseOverIcon.length == 0) {
                this.rolloverIcon = this.fui;
            } else {
                this.rolloverIcon = this.fri;
            }
            this.upSkin = this.fus;
            this.downSkin = this.fds;
            this.disabledSkin = this.dfs;
            this.upIcon = this.fui;
            this.downIcon = this.fdi;
            this.disabledIcon = this.dfi;
        }
        this.__state = state;
    };
    _r2.setState = function (state) {
        if (state != this.__state) {
            this.setStateVar(state);
            this.invalidate();
        }
    };
    _r2.size = function (Void) {
        this.refresh();
    };
    _r2.draw = function (Void) {
        if (this.initializing) {
            this.initializing = false;
            this.skinName.visible = true;
            this.iconName.visible = true;
        }
        this.size();
    };
    _r2.getState = function (Void) {
        return this.__state;
    };
    _r2.setToggle = function (val) {
        this.__toggle = val;
        if (this.__toggle == false) {
            this.setState(false);
        }
    };
    _r2.getToggle = function (Void) {
        return this.__toggle;
    };
    _r2.__set__toggle = function (val) {
        this.setToggle(val);
        return this.__get__toggle();
        <UNDERFLOW>;
    };
    _r2.__get__toggle = function () {
        return this.getToggle();
    };
    _r2.__set__value = function (val) {
        this.setSelected(val);
        return this.__get__value();
        <UNDERFLOW>;
    };
    _r2.__get__value = function () {
        return this.getSelected();
    };
    _r2.__set__selected = function (val) {
        this.setSelected(val);
        return this.__get__selected();
        <UNDERFLOW>;
    };
    _r2.__get__selected = function () {
        return this.getSelected();
    };
    _r2.setSelected = function (val) {
        if (this.__toggle) {
            this.setState(val);
        } else {
            this.setState(!this.initializing ? this.__state : val);
        }
    };
    _r2.getSelected = function () {
        return this.__state;
    };
    _r2.setEnabled = function (val) {
        if (this.enabled != val) {
            super.setEnabled(val);
            this.invalidate();
        }
    };
    _r2.onPress = function (Void) {
        this.pressFocus();
        this.phase = "down";
        this.refresh();
        this.dispatchEvent({type: "buttonDown"});
        if (this.autoRepeat) {
            this.interval = setInterval(this, "onPressDelay", this.getStyle("repeatDelay"));
        }
    };
    _r2.onPressDelay = function (Void) {
        this.dispatchEvent({type: "buttonDown"});
        if (this.autoRepeat) {
            clearInterval(this.interval);
            this.interval = setInterval(this, "onPressRepeat", this.getStyle("repeatInterval"));
        }
    };
    _r2.onPressRepeat = function (Void) {
        this.dispatchEvent({type: "buttonDown"});
        updateAfterEvent();
    };
    _r2.onRelease = function (Void) {
        this.releaseFocus();
        this.phase = "rollover";
        if (this.interval != undefined) {
            clearInterval(this.interval);
            delete this.interval;
        }
        if (this.getToggle()) {
            this.setState(!this.getState());
        } else {
            this.refresh();
        }
        this.dispatchEvent({type: "click"});
    };
    _r2.onDragOut = function (Void) {
        this.phase = "up";
        this.refresh();
        this.dispatchEvent({type: "buttonDragOut"});
    };
    _r2.onDragOver = function (Void) {
        if (this.phase != "up") {
            this.onPress();
            return undefined;
        } else {
            this.phase = "down";
            this.refresh();
        }
    };
    _r2.onReleaseOutside = function (Void) {
        this.releaseFocus();
        this.phase = "up";
        if (this.interval != undefined) {
            clearInterval(this.interval);
            delete this.interval;
        }
    };
    _r2.onRollOver = function (Void) {
        this.phase = "rollover";
        this.refresh();
    };
    _r2.onRollOut = function (Void) {
        this.phase = "up";
        this.refresh();
    };
    _r2.getLabel = function (Void) {
        return this.fui.text;
    };
    _r2.setLabel = function (val) {
        if (typeof this.fui == "string") {
            this.createLabel("fui", 8, val);
            this.fui.styleName = this;
        } else {
            this.fui.text = val;
        }
        _r4 = this.fui._getTextFormat();
        _r2 = _r4.getTextExtent2(val);
        this.fui._width = _r2.width + 5;
        this.fui._height = _r2.height + 5;
        this.iconName = this.fui;
        this.setView(this.__state);
    };
    _r2.__get__emphasized = function () {
        return this.__emphasized;
    };
    _r2.__set__emphasized = function (val) {
        this.__emphasized = val;
        _r2 = 0;
        while (_r2 < 8) {
            this[this.idNames[_r2]] = this.stateNames[_r2] + "Skin";
            if (typeof this[this.idNames[_r2 + 8]] == "movieclip") {
                this[this.idNames[_r2 + 8]] = this.stateNames[_r2] + "Icon";
            }
            _r2 = _r2 + 1;
        }
        this.showEmphasized(this.__emphasized);
        this.setStateVar(this.__state);
        this.invalidateStyle();
        return this.__get__emphasized();
        <UNDERFLOW>;
    };
    _r2.keyDown = function (e) {
        if (e.code == 32) {
            this.onPress();
        }
    };
    _r2.keyUp = function (e) {
        if (e.code == 32) {
            this.onRelease();
        }
    };
    _r2.onKillFocus = function (newFocus) {
        super.onKillFocus();
        if (this.phase != "up") {
            this.phase = "up";
            this.refresh();
        }
    };
    _r1.symbolName = "SimpleButton";
    _r1.symbolOwner = mx.controls.SimpleButton;
    _r1.version = "2.0.2.126";
    _r2.className = "SimpleButton";
    _r2.style3dInset = 4;
    _r2.btnOffset = 1;
    _r2.__toggle = false;
    _r2.__state = false;
    _r2.__emphasized = false;
    _r2.__emphatic = false;
    _r1.falseUp = 0;
    _r1.falseDown = 1;
    _r1.falseOver = 2;
    _r1.falseDisabled = 3;
    _r1.trueUp = 4;
    _r1.trueDown = 5;
    _r1.trueOver = 6;
    _r1.trueDisabled = 7;
    _r2.falseUpSkin = "SimpleButtonUp";
    _r2.falseDownSkin = "SimpleButtonIn";
    _r2.falseOverSkin = "";
    _r2.falseDisabledSkin = "SimpleButtonUp";
    _r2.trueUpSkin = "SimpleButtonIn";
    _r2.trueDownSkin = "";
    _r2.trueOverSkin = "";
    _r2.trueDisabledSkin = "SimpleButtonIn";
    _r2.falseUpIcon = "";
    _r2.falseDownIcon = "";
    _r2.falseOverIcon = "";
    _r2.falseDisabledIcon = "";
    _r2.trueUpIcon = "";
    _r2.trueDownIcon = "";
    _r2.trueOverIcon = "";
    _r2.trueDisabledIcon = "";
    _r2.phase = "up";
    _r2.fui = "falseUpIcon";
    _r2.fus = "falseUpSkin";
    _r2.fdi = "falseDownIcon";
    _r2.fds = "falseDownSkin";
    _r2.frs = "falseOverSkin";
    _r2.fri = "falseOverIcon";
    _r2.dfi = "falseDisabledIcon";
    _r2.dfs = "falseDisabledSkin";
    _r2.tui = "trueUpIcon";
    _r2.tus = "trueUpSkin";
    _r2.tdi = "trueDownIcon";
    _r2.tds = "trueDownSkin";
    _r2.trs = "trueOverSkin";
    _r2.tri = "trueOverIcon";
    _r2.dts = "trueDisabledSkin";
    _r2.dti = "trueDisabledIcon";
    _r2.rolloverSkin = mx.controls.SimpleButton.prototype.frs;
    _r2.rolloverIcon = mx.controls.SimpleButton.prototype.fri;
    _r2.upSkin = mx.controls.SimpleButton.prototype.fus;
    _r2.downSkin = mx.controls.SimpleButton.prototype.fds;
    _r2.disabledSkin = mx.controls.SimpleButton.prototype.dfs;
    _r2.upIcon = mx.controls.SimpleButton.prototype.fui;
    _r2.downIcon = mx.controls.SimpleButton.prototype.fdi;
    _r2.disabledIcon = mx.controls.SimpleButton.prototype.dfi;
    _r2.initializing = true;
    _r2.idNames = ["fus", "fds", "frs", "dfs", "tus", "tds", "trs", "dts", "fui", "fdi", "fri", "dfi", "tui", "tdi", "tri", "dti"];
    _r2.stateNames = ["falseUp", "falseDown", "falseOver", "falseDisabled", "trueUp", "trueDown", "trueOver", "trueDisabled"];
    _r2.refNames = ["upSkin", "downSkin", "rolloverSkin", "disabledSkin"];
    _r2.tagMap = {falseUpSkin: 0, falseDownSkin: 1, falseOverSkin: 2, falseDisabledSkin: 3, trueUpSkin: 4, trueDownSkin: 5, trueOverSkin: 6, trueDisabledSkin: 7, falseUpIcon: 0, falseDownIcon: 1, falseOverIcon: 2, falseDisabledIcon: 3, trueUpIcon: 4, trueDownIcon: 5, trueOverIcon: 6, trueDisabledIcon: 7};
}
ASSetPropFlags(mx.controls.SimpleButton.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("emphasized", _r2.__get__emphasized, _r2.__set__emphasized)', '_r2.addProperty("selected", _r2.__get__selected, _r2.__set__selected)', '_r2.addProperty("toggle", _r2.__get__toggle, _r2.__set__toggle)', '_r2.addProperty("value", _r2.__get__value, _r2.__set__value)'] */
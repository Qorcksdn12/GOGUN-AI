if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles) {
    _global.mx.styles = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles.CSSSetStyle) {
    mx.styles.CSSSetStyle = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r2._setStyle = function (styleProp, newValue) {
        this[styleProp] = newValue;
        if (mx.styles.StyleManager.TextStyleMap[styleProp] != undefined) {
            if (styleProp == "color") {
                if (isNaN(newValue)) {
                    newValue = mx.styles.StyleManager.getColorName(newValue);
                    this[styleProp] = newValue;
                    if (newValue == undefined) {
                        return undefined;
                    }
                }
            }
            _level0.changeTextStyleInChildren(styleProp);
            return undefined;
        }
        if (mx.styles.StyleManager.isColorStyle(styleProp)) {
            if (isNaN(newValue)) {
                newValue = mx.styles.StyleManager.getColorName(newValue);
                this[styleProp] = newValue;
                if (newValue == undefined) {
                    return undefined;
                }
            }
            if (styleProp == "themeColor") {
                _r7 = mx.styles.StyleManager.colorNames.haloBlue;
                _r6 = mx.styles.StyleManager.colorNames.haloGreen;
                _r8 = mx.styles.StyleManager.colorNames.haloOrange;
                _r4 = {};
                _r4[_r7] = 12188666;
                _r4[_r6] = 13500353;
                _r4[_r8] = 16766319;
                _r5 = {};
                _r5[_r7] = 13958653;
                _r5[_r6] = 14942166;
                _r5[_r8] = 16772787;
                _r9 = _r4[newValue];
                _r10 = _r5[newValue];
                if (_r9 == undefined) {
                    _r9 = newValue;
                }
                if (_r10 == undefined) {
                    _r10 = newValue;
                }
                this.setStyle("selectionColor", _r9);
                this.setStyle("rollOverColor", _r10);
            }
            _level0.changeColorStyleInChildren(this.styleName, styleProp, newValue);
        } else {
            if (styleProp == "backgroundColor" && isNaN(newValue)) {
                newValue = mx.styles.StyleManager.getColorName(newValue);
                this[styleProp] = newValue;
                if (newValue == undefined) {
                    return undefined;
                }
            }
            _level0.notifyStyleChangeInChildren(this.styleName, styleProp, newValue);
        }
    };
    _r2.changeTextStyleInChildren = function (styleProp) {
        _r4 = getTimer();
        _r5 = undefined;
        while ((_r0 = /*enum*/this) != null) {
            _r5 = _r0;
            _r2 = this[_r5];
            if (_r2._parent == this) {
                if (_r2.searchKey != _r4) {
                    if (_r2.stylecache != undefined) {
                        delete _r2.stylecache.tf;
                        delete _r2.stylecache[styleProp];
                    }
                    _r2.invalidateStyle(styleProp);
                    _r2.changeTextStyleInChildren(styleProp);
                    _r2.searchKey = _r4;
                }
            }
        }
        /* leftover stack: ['null'] */
    };
    _r2.changeColorStyleInChildren = function (sheetName, colorStyle, newValue) {
        _r6 = getTimer();
        _r7 = undefined;
        while ((_r0 = /*enum*/this) != null) {
            _r7 = _r0;
            _r2 = this[_r7];
            if (_r2._parent == this) {
                if (_r2.searchKey != _r6) {
                    if (_r2.getStyleName() == sheetName || sheetName == undefined || sheetName == "_global") {
                        if (_r2.stylecache != undefined) {
                            delete _r2.stylecache[colorStyle];
                        }
                        if (typeof _r2._color == "string") {
                            if (_r2._color == colorStyle) {
                                _r4 = _r2.getStyle(colorStyle);
                                if (colorStyle == "color") {
                                    if (this.stylecache.tf.color != undefined) {
                                        this.stylecache.tf.color = _r4;
                                    }
                                }
                                _r2.setColor(_r4);
                            }
                        } else {
                            if (_r2._color[colorStyle] != undefined) {
                                if (typeof _r2 != "movieclip") {
                                    _r2._parent.invalidateStyle();
                                } else {
                                    _r2.invalidateStyle(colorStyle);
                                }
                            }
                        }
                    }
                    _r2.changeColorStyleInChildren(sheetName, colorStyle, newValue);
                    _r2.searchKey = _r6;
                }
            }
        }
        /* leftover stack: ['null'] */
    };
    _r2.notifyStyleChangeInChildren = function (sheetName, styleProp, newValue) {
        _r5 = getTimer();
        _r6 = undefined;
        while ((_r0 = /*enum*/this) != null) {
            _r6 = _r0;
            _r2 = this[_r6];
            if (_r2._parent == this) {
                if (_r2.searchKey != _r5) {
                    if (_r2.styleName == sheetName || !(_r2.styleName == undefined) && typeof _r2.styleName == "movieclip" || sheetName == undefined) {
                        if (_r2.stylecache != undefined) {
                            delete _r2.stylecache[styleProp];
                            delete _r2.stylecache.tf;
                        }
                        delete _r2.enabledColor;
                        _r2.invalidateStyle(styleProp);
                    }
                    _r2.notifyStyleChangeInChildren(sheetName, styleProp, newValue);
                    _r2.searchKey = _r5;
                }
            }
        }
        /* leftover stack: ['null'] */
    };
    _r2.setStyle = function (styleProp, newValue) {
        if (this.stylecache != undefined) {
            delete this.stylecache[styleProp];
            delete this.stylecache.tf;
        }
        this[styleProp] = newValue;
        if (mx.styles.StyleManager.isColorStyle(styleProp)) {
            if (isNaN(newValue)) {
                newValue = mx.styles.StyleManager.getColorName(newValue);
                this[styleProp] = newValue;
                if (newValue == undefined) {
                    return undefined;
                }
            }
            if (styleProp == "themeColor") {
                _r10 = mx.styles.StyleManager.colorNames.haloBlue;
                _r9 = mx.styles.StyleManager.colorNames.haloGreen;
                _r11 = mx.styles.StyleManager.colorNames.haloOrange;
                _r6 = {};
                _r6[_r10] = 12188666;
                _r6[_r9] = 13500353;
                _r6[_r11] = 16766319;
                _r7 = {};
                _r7[_r10] = 13958653;
                _r7[_r9] = 14942166;
                _r7[_r11] = 16772787;
                _r12 = _r6[newValue];
                _r13 = _r7[newValue];
                if (_r12 == undefined) {
                    _r12 = newValue;
                }
                if (_r13 == undefined) {
                    _r13 = newValue;
                }
                this.setStyle("selectionColor", _r12);
                this.setStyle("rollOverColor", _r13);
            }
            if (typeof this._color == "string") {
                if (this._color == styleProp) {
                    if (styleProp == "color") {
                        if (this.stylecache.tf.color != undefined) {
                            this.stylecache.tf.color = newValue;
                        }
                    }
                    this.setColor(newValue);
                }
            } else {
                if (this._color[styleProp] != undefined) {
                    this.invalidateStyle(styleProp);
                }
            }
            this.changeColorStyleInChildren(undefined, styleProp, newValue);
        } else {
            if (styleProp == "backgroundColor" && isNaN(newValue)) {
                newValue = mx.styles.StyleManager.getColorName(newValue);
                this[styleProp] = newValue;
                if (newValue == undefined) {
                    return undefined;
                }
            }
            this.invalidateStyle(styleProp);
        }
        if (mx.styles.StyleManager.isInheritingStyle(styleProp) || styleProp == "styleName") {
            _r8 = undefined;
            _r5 = newValue;
            if (styleProp == "styleName") {
                _r8 = typeof newValue != "string" ? _r5 : _global.styles[newValue];
                _r5 = _r8.themeColor;
                if (_r5 != undefined) {
                    _r8.selectionColor = _r0 = _r5;
                    _r8.rollOverColor = _r0;
                }
            }
            this.notifyStyleChangeInChildren(undefined, styleProp, newValue);
        }
    };
    _r1.enableRunTimeCSS = function () {
    };
    _r1.classConstruct = function () {
        _r2 = MovieClip.prototype;
        _r3 = mx.styles.CSSSetStyle.prototype;
        mx.styles.CSSStyleDeclaration.prototype.setStyle = _r3._setStyle;
        _r2.changeTextStyleInChildren = _r3.changeTextStyleInChildren;
        _r2.changeColorStyleInChildren = _r3.changeColorStyleInChildren;
        _r2.notifyStyleChangeInChildren = _r3.notifyStyleChangeInChildren;
        _r2.setStyle = _r3.setStyle;
        _global.ASSetPropFlags(_r2, "changeTextStyleInChildren", 1);
        _global.ASSetPropFlags(_r2, "changeColorStyleInChildren", 1);
        _global.ASSetPropFlags(_r2, "notifyStyleChangeInChildren", 1);
        _global.ASSetPropFlags(_r2, "setStyle", 1);
        _r4 = TextField.prototype;
        _r4.setStyle = _r2.setStyle;
        _r4.changeTextStyleInChildren = _r3.changeTextStyleInChildren;
        return true;
    };
    _r1.classConstructed = mx.styles.CSSSetStyle.classConstruct();
    _r1.CSSStyleDeclarationDependency = mx.styles.CSSStyleDeclaration;
}
ASSetPropFlags(mx.styles.CSSSetStyle.prototype, null, 1);
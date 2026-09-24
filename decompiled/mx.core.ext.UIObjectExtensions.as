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
if (!_global.mx.core.ext.UIObjectExtensions) {
    mx.core.ext.UIObjectExtensions = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.addGeometry = function (tf, ui) {
        tf.addProperty("width", ui.__get__width, null);
        tf.addProperty("height", ui.__get__height, null);
        tf.addProperty("left", ui.__get__left, null);
        tf.addProperty("x", ui.__get__x, null);
        tf.addProperty("top", ui.__get__top, null);
        tf.addProperty("y", ui.__get__y, null);
        tf.addProperty("right", ui.__get__right, null);
        tf.addProperty("bottom", ui.__get__bottom, null);
        tf.addProperty("visible", ui.__get__visible, ui.__set__visible);
    };
    _r1.Extensions = function () {
        if (mx.core.ext.UIObjectExtensions.bExtended == true) {
            return true;
        }
        mx.core.ext.UIObjectExtensions.bExtended = true;
        _r6 = mx.core.UIObject.prototype;
        _r9 = mx.skins.SkinElement.prototype;
        mx.core.ext.UIObjectExtensions.addGeometry(_r9, _r6);
        mx.events.UIEventDispatcher.initialize(_r6);
        _r13 = mx.skins.ColoredSkinElement;
        mx.styles.CSSTextStyles.addTextStyles(_r6);
        _r5 = MovieClip.prototype;
        _r5.getTopLevel = _r6.getTopLevel;
        _r5.createLabel = _r6.createLabel;
        _r5.createObject = _r6.createObject;
        _r5.createClassObject = _r6.createClassObject;
        _r5.createEmptyObject = _r6.createEmptyObject;
        _r5.destroyObject = _r6.destroyObject;
        _global.ASSetPropFlags(_r5, "getTopLevel", 1);
        _global.ASSetPropFlags(_r5, "createLabel", 1);
        _global.ASSetPropFlags(_r5, "createObject", 1);
        _global.ASSetPropFlags(_r5, "createClassObject", 1);
        _global.ASSetPropFlags(_r5, "createEmptyObject", 1);
        _global.ASSetPropFlags(_r5, "destroyObject", 1);
        _r5.__getTextFormat = _r6.__getTextFormat;
        _r5._getTextFormat = _r6._getTextFormat;
        _r5.getStyleName = _r6.getStyleName;
        _r5.getStyle = _r6.getStyle;
        _global.ASSetPropFlags(_r5, "__getTextFormat", 1);
        _global.ASSetPropFlags(_r5, "_getTextFormat", 1);
        _global.ASSetPropFlags(_r5, "getStyleName", 1);
        _global.ASSetPropFlags(_r5, "getStyle", 1);
        _r7 = TextField.prototype;
        mx.core.ext.UIObjectExtensions.addGeometry(_r7, _r6);
        _r7.addProperty("enabled", function () {
            return this.__enabled;
        }, function (x) {
            this.__enabled = x;
            this.invalidateStyle();
        });
        _r7.move = _r9.move;
        _r7.setSize = _r9.setSize;
        _r7.invalidateStyle = function () {
            this.invalidateFlag = true;
        };
        _r7.draw = function () {
            if (this.invalidateFlag) {
                this.invalidateFlag = false;
                _r2 = this._getTextFormat();
                this.setTextFormat(_r2);
                this.setNewTextFormat(_r2);
                this.embedFonts = _r2.embedFonts == true;
                if (this.__text != undefined) {
                    if (this.text == "") {
                        this.text = this.__text;
                    }
                    delete this.__text;
                }
                this._visible = true;
            }
        };
        _r7.setColor = function (color) {
            this.textColor = color;
        };
        _r7.getStyle = _r5.getStyle;
        _r7.__getTextFormat = _r6.__getTextFormat;
        _r7.setValue = function (v) {
            this.text = v;
        };
        _r7.getValue = function () {
            return this.text;
        };
        _r7.addProperty("value", function () {
            return this.getValue();
        }, function (v) {
            this.setValue(v);
        });
        _r7._getTextFormat = function () {
            _r2 = this.stylecache.tf;
            if (_r2 != undefined) {
                return _r2;
            }
            _r2 = new TextFormat();
            this.__getTextFormat(_r2);
            this.stylecache.tf = _r2;
            if (this.__enabled == false) {
                if (this.enabledColor == undefined) {
                    _r4 = this.getTextFormat();
                    this.enabledColor = _r4.color;
                }
                _r3 = this.getStyle("disabledColor");
                _r2.color = _r3;
            } else {
                if (this.enabledColor != undefined) {
                    if (_r2.color == undefined) {
                        _r2.color = this.enabledColor;
                    }
                }
            }
            return _r2;
        };
        _r7.getPreferredWidth = function () {
            this.draw();
            return this.textWidth + 4;
        };
        _r7.getPreferredHeight = function () {
            this.draw();
            return this.textHeight + 4;
        };
        TextFormat.prototype.getTextExtent2 = function (s) {
            _r3 = _root._getTextExtent;
            if (_r3 == undefined) {
                _root.createTextField("_getTextExtent", -2, 0, 0, 1000, 100);
                _r3 = _root._getTextExtent;
                _r3._visible = false;
            }
            _root._getTextExtent.text = s;
            _r4 = this.align;
            this.align = "left";
            _root._getTextExtent.setTextFormat(this);
            this.align = _r4;
            return {width: _r3.textWidth, height: _r3.textHeight};
        };
        if (_global.style == undefined) {
            _global.style = new mx.styles.CSSStyleDeclaration();
            _global.cascadingStyles = true;
            _global.styles = new Object();
            _global.skinRegistry = new Object();
            if (_global._origWidth == undefined) {
                _global.origWidth = Stage.width;
                _global.origHeight = Stage.height;
            }
        }
        _r4 = _root;
        while (_r4._parent != undefined) {
            _r4 = _r4._parent;
        }
        _r4.addProperty("width", function () {
            return Stage.width;
        }, null);
        _r4.addProperty("height", function () {
            return Stage.height;
        }, null);
        _global.ASSetPropFlags(_r4, "width", 1);
        _global.ASSetPropFlags(_r4, "height", 1);
        return true;
    };
    _r1.bExtended = false;
    _r1.UIObjectExtended = mx.core.ext.UIObjectExtensions.Extensions();
    _r1.UIObjectDependency = mx.core.UIObject;
    _r1.SkinElementDependency = mx.skins.SkinElement;
    _r1.CSSTextStylesDependency = mx.styles.CSSTextStyles;
    _r1.UIEventDispatcherDependency = mx.events.UIEventDispatcher;
}
ASSetPropFlags(mx.core.ext.UIObjectExtensions.prototype, null, 1);
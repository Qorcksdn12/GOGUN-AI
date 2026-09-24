if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.core) {
    _global.mx.core = new Object();
}
<UNDERFLOW>;
if (!_global.mx.core.UIObject) {
    mx.core.UIObject = _r1 = function () {
        super[undefined]();
        this.constructObject();
    };
    mx.core.UIObject.prototype = _r2 = new MovieClip();
    _r2.__get__width = function () {
        return this._width;
    };
    _r2.__get__height = function () {
        return this._height;
    };
    _r2.__get__left = function () {
        return this._x;
    };
    _r2.__get__x = function () {
        return this._x;
    };
    _r2.__get__top = function () {
        return this._y;
    };
    _r2.__get__y = function () {
        return this._y;
    };
    _r2.__get__right = function () {
        return this._parent.width - (this._x + this.__get__width());
    };
    _r2.__get__bottom = function () {
        return this._parent.height - (this._y + this.__get__height());
    };
    _r2.getMinHeight = function (Void) {
        return this._minHeight;
    };
    _r2.setMinHeight = function (h) {
        this._minHeight = h;
    };
    _r2.__get__minHeight = function () {
        return this.getMinHeight();
    };
    _r2.__set__minHeight = function (h) {
        this.setMinHeight(h);
        return this.__get__minHeight();
        <UNDERFLOW>;
    };
    _r2.getMinWidth = function (Void) {
        return this._minWidth;
    };
    _r2.setMinWidth = function (w) {
        this._minWidth = w;
    };
    _r2.__get__minWidth = function () {
        return this.getMinWidth();
    };
    _r2.__set__minWidth = function (w) {
        this.setMinWidth(w);
        return this.__get__minWidth();
        <UNDERFLOW>;
    };
    _r2.setVisible = function (x, noEvent) {
        if (x != this._visible) {
            this._visible = x;
            if (noEvent != true) {
                this.dispatchEvent({type: !x ? "hide" : "reveal"});
            }
        }
    };
    _r2.__get__visible = function () {
        return this._visible;
    };
    _r2.__set__visible = function (x) {
        this.setVisible(x, false);
        return this.__get__visible();
        <UNDERFLOW>;
    };
    _r2.__get__scaleX = function () {
        return this._xscale;
    };
    _r2.__set__scaleX = function (x) {
        this._xscale = x;
        return this.__get__scaleX();
        <UNDERFLOW>;
    };
    _r2.__get__scaleY = function () {
        return this._yscale;
    };
    _r2.__set__scaleY = function (y) {
        this._yscale = y;
        return this.__get__scaleY();
        <UNDERFLOW>;
    };
    _r2.doLater = function (obj, fn) {
        if (this.methodTable == undefined) {
            this.methodTable = new Array();
        }
        this.methodTable.push({obj: obj, fn: fn});
        this.onEnterFrame = this.doLaterDispatcher;
    };
    _r2.doLaterDispatcher = function (Void) {
        delete this.onEnterFrame;
        if (this.invalidateFlag) {
            this.redraw();
        }
        _r3 = this.methodTable;
        this.methodTable = new Array();
        if (_r3.length > 0) {
            _r2 = undefined;
            while ((_r2 = _r3.shift()) != undefined) {
                _r2.obj[_r2.fn]();
            }
        }
    };
    _r2.cancelAllDoLaters = function (Void) {
        delete this.onEnterFrame;
        this.methodTable = new Array();
    };
    _r2.invalidate = function (Void) {
        this.invalidateFlag = true;
        this.onEnterFrame = this.doLaterDispatcher;
    };
    _r2.invalidateStyle = function (Void) {
        this.invalidate();
    };
    _r2.redraw = function (bAlways) {
        if (this.invalidateFlag || bAlways) {
            this.invalidateFlag = false;
            _r2 = undefined;
            while ((_r0 = /*enum*/this.tfList) != null) {
                _r2 = _r0;
                this.tfList[_r2].draw();
            }
            this.draw();
            this.dispatchEvent({type: "draw"});
        }
        /* leftover stack: ['null'] */
    };
    _r2.draw = function (Void) {
    };
    _r2.move = function (x, y, noEvent) {
        _r3 = this._x;
        _r2 = this._y;
        this._x = x;
        this._y = y;
        if (noEvent != true) {
            this.dispatchEvent({type: "move", oldX: _r3, oldY: _r2});
        }
    };
    _r2.setSize = function (w, h, noEvent) {
        _r2 = this.__width;
        _r3 = this.__height;
        this.__width = w;
        this.__height = h;
        this.size();
        if (noEvent != true) {
            this.dispatchEvent({type: "resize", oldWidth: _r2, oldHeight: _r3});
        }
    };
    _r2.size = function (Void) {
        this._width = this.__width;
        this._height = this.__height;
    };
    _r2.drawRect = function (x1, y1, x2, y2) {
        this.moveTo(x1, y1);
        this.lineTo(x2, y1);
        this.lineTo(x2, y2);
        this.lineTo(x1, y2);
        this.lineTo(x1, y1);
    };
    _r2.createLabel = function (name, depth, text) {
        this.createTextField(name, depth, 0, 0, 0, 0);
        _r2 = this[name];
        _r2._color = mx.core.UIObject.textColorList;
        _r2._visible = false;
        _r2.__text = text;
        if (this.tfList == undefined) {
            this.tfList = new Object();
        }
        this.tfList[name] = _r2;
        _r2.invalidateStyle();
        this.invalidate();
        _r2.styleName = this;
        return _r2;
    };
    _r2.createObject = function (linkageName, id, depth, initobj) {
        return this.attachMovie(linkageName, id, depth, initobj);
    };
    _r2.createClassObject = function (className, id, depth, initobj) {
        _r3 = className.symbolName == undefined;
        if (_r3) {
            Object.registerClass(className.symbolOwner.symbolName, className);
        }
        _r4 = this.createObject(className.symbolOwner.symbolName, id, depth, initobj);
        if (_r3) {
            Object.registerClass(className.symbolOwner.symbolName, className.symbolOwner);
        }
        return _r4;
    };
    _r2.createEmptyObject = function (id, depth) {
        return this.createClassObject(mx.core.UIObject, id, depth);
    };
    _r2.destroyObject = function (id) {
        _r2 = this[id];
        if (_r2.getDepth() < 0) {
            _r4 = this.buildDepthTable();
            _r5 = this.findNextAvailableDepth(0, _r4, "up");
            _r3 = _r5;
            _r2.swapDepths(_r3);
        }
        _r2.removeMovieClip();
        delete this[id];
    };
    _r2.getSkinIDName = function (tag) {
        return this.idNames[tag];
    };
    _r2.setSkin = function (tag, linkageName, initObj) {
        if (_global.skinRegistry[linkageName] == undefined) {
            mx.skins.SkinElement.registerElement(linkageName, mx.skins.SkinElement);
        }
        return this.createObject(linkageName, this.getSkinIDName(tag), tag, initObj);
    };
    _r2.createSkin = function (tag) {
        _r2 = this.getSkinIDName(tag);
        this.createEmptyObject(_r2, tag);
        return this[_r2];
    };
    _r2.createChildren = function (Void) {
    };
    _r2._createChildren = function (Void) {
        this.createChildren();
        this.childrenCreated = true;
    };
    _r2.constructObject = function (Void) {
        if (this._name == undefined) {
            return undefined;
        }
        this.init();
        this._createChildren();
        this.createAccessibilityImplementation();
        this._endInit();
        if (this.validateNow) {
            this.redraw(true);
        } else {
            this.invalidate();
        }
    };
    _r2.initFromClipParameters = function (Void) {
        _r4 = false;
        _r2 = undefined;
        while ((_r0 = /*enum*/this.clipParameters) != null) {
            _r2 = _r0;
            if (this.hasOwnProperty(_r2)) {
                _r4 = true;
                this["def_" + _r2] = this[_r2];
                delete this[_r2];
            }
        }
        if (_r4) {
            while ((_r0 = /*enum*/this.clipParameters) != null) {
                _r2 = _r0;
                _r3 = this["def_" + _r2];
                if (_r3 != undefined) {
                    this[_r2] = _r3;
                }
            }
        }
        /* leftover stack: ['null', 'null'] */
    };
    _r2.init = function (Void) {
        this.__width = this._width;
        this.__height = this._height;
        if (this.initProperties == undefined) {
            this.initFromClipParameters();
        } else {
            this.initProperties();
        }
        if (_global.cascadingStyles == true) {
            this.stylecache = new Object();
        }
    };
    _r2.getClassStyleDeclaration = function (Void) {
        _r4 = this;
        _r3 = this.className;
        while (_r3 != undefined) {
            if (this.ignoreClassStyleDeclaration[_r3] == undefined) {
                if (_global.styles[_r3] != undefined) {
                    return _global.styles[_r3];
                }
            }
            _r4 = _r4.__proto__;
            _r3 = _r4.className;
        }
    };
    _r2.setColor = function (color) {
    };
    _r2.__getTextFormat = function (tf, bAll) {
        _r8 = this.stylecache.tf;
        if (_r8 != undefined) {
            _r3 = undefined;
            while ((_r0 = /*enum*/mx.styles.StyleManager.TextFormatStyleProps) != null) {
                _r3 = _r0;
                if (bAll || mx.styles.StyleManager.TextFormatStyleProps[_r3]) {
                    if (tf[_r3] == undefined) {
                        tf[_r3] = _r8[_r3];
                    }
                }
            }
            return false;
        }
        _r6 = false;
        while ((_r0 = /*enum*/mx.styles.StyleManager.TextFormatStyleProps) != null) {
            _r3 = _r0;
            if (bAll || mx.styles.StyleManager.TextFormatStyleProps[_r3]) {
                if (tf[_r3] == undefined) {
                    _r5 = this._tf[_r3];
                    if (_r5 != undefined) {
                        tf[_r3] = _r5;
                    } else {
                        if (_r3 == "font" && !(this.fontFamily == undefined)) {
                            tf[_r3] = this.fontFamily;
                        } else {
                            if (_r3 == "size" && !(this.fontSize == undefined)) {
                                tf[_r3] = this.fontSize;
                            } else {
                                if (_r3 == "color" && !(this.color == undefined)) {
                                    tf[_r3] = this.color;
                                } else {
                                    if (_r3 == "leftMargin" && !(this.marginLeft == undefined)) {
                                        tf[_r3] = this.marginLeft;
                                    } else {
                                        if (_r3 == "rightMargin" && !(this.marginRight == undefined)) {
                                            tf[_r3] = this.marginRight;
                                        } else {
                                            if (_r3 == "italic" && !(this.fontStyle == undefined)) {
                                                tf[_r3] = this.fontStyle == _r3;
                                            } else {
                                                if (_r3 == "bold" && !(this.fontWeight == undefined)) {
                                                    tf[_r3] = this.fontWeight == _r3;
                                                } else {
                                                    if (_r3 == "align" && !(this.textAlign == undefined)) {
                                                        tf[_r3] = this.textAlign;
                                                    } else {
                                                        if (_r3 == "indent" && !(this.textIndent == undefined)) {
                                                            tf[_r3] = this.textIndent;
                                                        } else {
                                                            if (_r3 == "underline" && !(this.textDecoration == undefined)) {
                                                                tf[_r3] = this.textDecoration == _r3;
                                                            } else {
                                                                if (_r3 == "embedFonts" && !(this.embedFonts == undefined)) {
                                                                    tf[_r3] = this.embedFonts;
                                                                } else {
                                                                    _r6 = true;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if (_r6) {
            _r9 = this.styleName;
            if (_r9 != undefined) {
                if (typeof _r9 != "string") {
                    _r6 = _r9.__getTextFormat(tf, true, this);
                } else {
                    if (_global.styles[_r9] != undefined) {
                        _r6 = _global.styles[_r9].__getTextFormat(tf, true, this);
                    }
                }
            }
        }
        if (_r6) {
            _r10 = this.getClassStyleDeclaration();
            if (_r10 != undefined) {
                _r6 = _r10.__getTextFormat(tf, true, this);
            }
        }
        if (_r6) {
            if (_global.cascadingStyles) {
                if (this._parent != undefined) {
                    _r6 = this._parent.__getTextFormat(tf, false);
                }
            }
        }
        if (_r6) {
            _r6 = _global.style.__getTextFormat(tf, true, this);
        }
        return _r6;
        /* leftover stack: ['null', 'null'] */
    };
    _r2._getTextFormat = function (Void) {
        _r2 = this.stylecache.tf;
        if (_r2 != undefined) {
            return _r2;
        }
        _r2 = new TextFormat();
        this.__getTextFormat(_r2, true);
        this.stylecache.tf = _r2;
        if (this.enabled == false) {
            _r3 = this.getStyle("disabledColor");
            _r2.color = _r3;
        }
        return _r2;
    };
    _r2.getStyleName = function (Void) {
        _r2 = this.styleName;
        if (_r2 != undefined) {
            if (typeof _r2 != "string") {
                return _r2.getStyleName();
            } else {
                return _r2;
            }
        }
        if (this._parent != undefined) {
            return this._parent.getStyleName();
        } else {
            return undefined;
        }
    };
    _r2.getStyle = function (styleProp) {
        _r3 = undefined;
        _global.getStyleCounter = _global.getStyleCounter + 1;
        if (this[styleProp] != undefined) {
            return this[styleProp];
        }
        _r6 = this.styleName;
        if (_r6 != undefined) {
            if (typeof _r6 != "string") {
                _r3 = _r6.getStyle(styleProp);
            } else {
                _r7 = _global.styles[_r6];
                _r3 = _r7.getStyle(styleProp);
            }
        }
        if (_r3 != undefined) {
            return _r3;
        }
        _r7 = this.getClassStyleDeclaration();
        if (_r7 != undefined) {
            _r3 = _r7[styleProp];
        }
        if (_r3 != undefined) {
            return _r3;
        }
        if (_global.cascadingStyles) {
            if (mx.styles.StyleManager.isInheritingStyle(styleProp) || mx.styles.StyleManager.isColorStyle(styleProp)) {
                _r5 = this.stylecache;
                if (_r5 != undefined) {
                    if (_r5[styleProp] != undefined) {
                        return _r5[styleProp];
                    }
                }
                if (this._parent != undefined) {
                    _r3 = this._parent.getStyle(styleProp);
                } else {
                    _r3 = _global.style[styleProp];
                }
                if (_r5 != undefined) {
                    _r5[styleProp] = _r3;
                }
                return _r3;
            }
        }
        if (_r3 == undefined) {
            _r3 = _global.style[styleProp];
        }
        return _r3;
    };
    _r1.mergeClipParameters = function (o, p) {
        while ((_r0 = /*enum*/p) != null) {
            _r3 = _r0;
            o[_r3] = p[_r3];
        }
        return true;
        /* leftover stack: ['null'] */
    };
    _r1.symbolName = "UIObject";
    _r1.symbolOwner = mx.core.UIObject;
    _r1.version = "2.0.2.126";
    _r1.textColorList = {color: 1, disabledColor: 1};
    _r2.invalidateFlag = false;
    _r2.lineWidth = 1;
    _r2.lineColor = 0;
    _r2.tabEnabled = false;
    _r2.clipParameters = {visible: 1, minHeight: 1, minWidth: 1, maxHeight: 1, maxWidth: 1, preferredHeight: 1, preferredWidth: 1};
}
ASSetPropFlags(mx.core.UIObject.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("bottom", _r2.__get__bottom, function () {\n})', '_r2.addProperty("height", _r2.__get__height, function () {\n})', '_r2.addProperty("left", _r2.__get__left, function () {\n})', '_r2.addProperty("minHeight", _r2.__get__minHeight, _r2.__set__minHeight)', '_r2.addProperty("minWidth", _r2.__get__minWidth, _r2.__set__minWidth)', '_r2.addProperty("right", _r2.__get__right, function () {\n})', '_r2.addProperty("scaleX", _r2.__get__scaleX, _r2.__set__scaleX)', '_r2.addProperty("scaleY", _r2.__get__scaleY, _r2.__set__scaleY)', '_r2.addProperty("top", _r2.__get__top, function () {\n})', '_r2.addProperty("visible", _r2.__get__visible, _r2.__set__visible)', '_r2.addProperty("width", _r2.__get__width, function () {\n})', '_r2.addProperty("x", _r2.__get__x, function () {\n})', '_r2.addProperty("y", _r2.__get__y, function () {\n})'] */
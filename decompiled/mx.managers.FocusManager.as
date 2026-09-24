if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers) {
    _global.mx.managers = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers.FocusManager) {
    mx.managers.FocusManager = _r1 = function () {
        super[undefined]();
    };
    mx.managers.FocusManager.prototype = _r2 = new mx.core.UIComponent();
    _r2.__get__defaultPushButton = function () {
        return this.__defaultPushButton;
    };
    _r2.__set__defaultPushButton = function (x) {
        if (x != this.__defaultPushButton) {
            this.__defaultPushButton.__set__emphasized(false);
            this.__defaultPushButton = x;
            this.defPushButton = x;
            x.__set__emphasized(true);
        }
        return this.__get__defaultPushButton();
        <UNDERFLOW>;
    };
    _r2.getMaxTabIndex = function (o) {
        _r3 = 0;
        _r6 = undefined;
        while ((_r0 = /*enum*/o) != null) {
            _r6 = _r0;
            _r2 = o[_r6];
            if (_r2._parent == o) {
                if (_r2.tabIndex != undefined) {
                    if (_r2.tabIndex > _r3) {
                        _r3 = _r2.tabIndex;
                    }
                }
                if (_r2.tabChildren == true) {
                    _r4 = this.getMaxTabIndex(_r2);
                    if (_r4 > _r3) {
                        _r3 = _r4;
                    }
                }
            }
        }
        return _r3;
        /* leftover stack: ['null'] */
    };
    _r2.getNextTabIndex = function (Void) {
        return this.getMaxTabIndex(this.form) + 1;
    };
    _r2.__get__nextTabIndex = function () {
        return this.getNextTabIndex();
    };
    _r2.relocate = function (Void) {
        _r2 = mx.managers.SystemManager.__get__screen();
        this.move(_r2.x - 1, _r2.y - 1);
    };
    _r2.init = function (Void) {
        super.init();
        this.tabEnabled = false;
        this._height = _r0 = 1;
        this._width = _r0;
        this._y = _r0 = -1;
        this._x = _r0;
        this._alpha = 0;
        this._parent.focusManager = this;
        this._parent.tabChildren = true;
        this._parent.tabEnabled = false;
        this.form = this._parent;
        this._parent.addEventListener("hide", this);
        this._parent.addEventListener("reveal", this);
        mx.managers.SystemManager.init();
        mx.managers.SystemManager.addFocusManager(this.form);
        this.tabCapture.tabIndex = 0;
        this.watch("enabled", this.enabledChanged);
        Selection.addListener(this);
        this.lastMouse = new Object();
        _global.ASSetPropFlags(this._parent, "focusManager", 1);
        _global.ASSetPropFlags(this._parent, "tabChildren", 1);
        _global.ASSetPropFlags(this._parent, "tabEnabled", 1);
    };
    _r2.enabledChanged = function (id, oldValue, newValue) {
        this._visible = newValue;
        return newValue;
    };
    _r2.activate = function (Void) {
        Key.addListener(this);
        this._visible = _r0 = true;
        this.activated = _r0;
        if (this.lastFocus != undefined) {
            this.bNeedFocus = true;
            if (!mx.managers.SystemManager.isMouseDown) {
                this.doLater(this, "restoreFocus");
            }
        }
    };
    _r2.deactivate = function (Void) {
        Key.removeListener(this);
        this._visible = _r0 = false;
        this.activated = _r0;
        _r2 = this.getSelectionFocus();
        _r3 = this.getActualFocus(_r2);
        if (this.isOurFocus(_r3)) {
            this.lastSelFocus = _r2;
            this.lastFocus = _r3;
        }
        this.cancelAllDoLaters();
    };
    _r2.isOurFocus = function (o) {
        if (o.focusManager == this) {
            return true;
        }
        while (o != undefined) {
            if (o.focusManager != undefined) {
                return false;
            }
            if (o._parent == this._parent) {
                return true;
            }
            o = o._parent;
        }
        return false;
    };
    _r2.onSetFocus = function (o, n) {
        if (n == null) {
            if (this.activated) {
                this.bNeedFocus = true;
            }
        } else {
            _r2 = this.getFocus();
            if (this.isOurFocus(_r2)) {
                this.bNeedFocus = false;
                this.lastFocus = _r2;
                this.lastSelFocus = n;
            }
        }
    };
    _r2.restoreFocus = function (Void) {
        _r2 = this.lastSelFocus.hscroll;
        if (_r2 != undefined) {
            _r5 = this.lastSelFocus.scroll;
            _r4 = this.lastSelFocus.background;
        }
        this.lastFocus.setFocus();
        _r3 = Selection;
        Selection.setSelection(_r3.lastBeginIndex, _r3.lastEndIndex);
        if (_r2 != undefined) {
            this.lastSelFocus.scroll = _r5;
            this.lastSelFocus.hscroll = _r2;
            this.lastSelFocus.background = _r4;
        }
    };
    _r2.onUnload = function (Void) {
        mx.managers.SystemManager.removeFocusManager(this.form);
    };
    _r2.setFocus = function (o) {
        if (o == null) {
            Selection.setFocus(null);
        } else {
            if (o.setFocus == undefined) {
                Selection.setFocus(o);
            } else {
                o.setFocus();
            }
        }
    };
    _r2.getActualFocus = function (o) {
        _r1 = o._parent;
        while (_r1 != undefined) {
            if (_r1.focusTextField != undefined) {
                while (_r1.focusTextField != undefined) {
                    o = _r1;
                    _r1 = _r1._parent;
                    if (_r1 == undefined) {
                        return undefined;
                    }
                    if (_r1.focusTextField == undefined) {
                        return o;
                    }
                }
            }
            if (_r1.tabEnabled != true) {
                return o;
            }
            o = _r1;
            _r1 = o._parent;
        }
        return undefined;
    };
    _r2.getSelectionFocus = function () {
        var m = Selection.getFocus();
        var o = eval(m);
        return o;
    };
    _r2.getFocus = function (Void) {
        _r2 = this.getSelectionFocus();
        return this.getActualFocus(_r2);
    };
    _r2.walkTree = function (p, index, groupName, dir, lookup, firstChild) {
        _r5 = true;
        _r11 = undefined;
        while ((_r0 = /*enum*/p) != null) {
            _r11 = _r0;
            _r2 = p[_r11];
            if (_r2._parent == p && !(_r2.enabled == false) && !(_r2._visible == false) && (_r2.tabEnabled == true || !(_r2.tabEnabled == false) && (!(_r2.onPress == undefined) || !(_r2.onRelease == undefined) || !(_r2.onReleaseOutside == undefined) || !(_r2.onDragOut == undefined) || !(_r2.onDragOver == undefined) || !(_r2.onRollOver == undefined) || !(_r2.onRollOut == undefined) || _r2 instanceof TextField))) {
                while (_r2._searchKey == this._searchKey) {
                }
                _r2._searchKey = this._searchKey;
                if (_r2 != this._lastTarget) {
                    while ((!(_r2.groupName == undefined) || !(groupName == undefined)) && _r2.groupName == groupName) {
                    }
                    while (_r2 instanceof TextField && _r2.selectable == false) {
                    }
                    if (_r5 || !(_r2.groupName == undefined) && _r2.groupName == this._firstNode.groupName && _r2.selected == true) {
                        if (firstChild) {
                            this._firstNode = _r2;
                            firstChild = false;
                        }
                    }
                    if (this._nextIsNext == true) {
                        if (!(_r2.groupName == undefined) && _r2.groupName == this._nextNode.groupName && _r2.selected == true || this._nextNode == undefined && (_r2.groupName == undefined || !(_r2.groupName == undefined) && !(_r2.groupName == groupName))) {
                            this._nextNode = _r2;
                        }
                    }
                    if (_r2.groupName == undefined || !(groupName == _r2.groupName)) {
                        if (!(this._lastx.groupName == undefined) && _r2.groupName == this._lastx.groupName && this._lastx.selected == true) {
                        } else {
                            this._lastx = _r2;
                        }
                    }
                } else {
                    this._prevNode = this._lastx;
                    this._needPrev = false;
                    this._nextIsNext = true;
                }
                if (_r2.tabIndex != undefined) {
                    if (_r2.tabIndex == index) {
                        if (this._foundList[_r2._name] == undefined) {
                            if (this._needPrev) {
                                this._prevObj = _r2;
                                this._needPrev = false;
                            }
                            this._nextObj = _r2;
                        }
                    }
                    if (dir && _r2.tabIndex > index) {
                        if (this._nextObj == undefined || this._nextObj.tabIndex > _r2.tabIndex && (_r2.groupName == undefined || this._nextObj.groupName == undefined || !(_r2.groupName == this._nextObj.groupName)) || !(this._nextObj.groupName == undefined) && this._nextObj.groupName == _r2.groupName && !(this._nextObj.selected == true) && (_r2.selected == true || this._nextObj.tabIndex > _r2.tabIndex)) {
                            this._nextObj = _r2;
                        }
                    } else {
                        if (!dir && _r2.tabIndex < index) {
                            if (this._prevObj == undefined || this._prevObj.tabIndex < _r2.tabIndex && (_r2.groupName == undefined || this._prevObj.groupName == undefined || !(_r2.groupName == this._prevObj.groupName)) || !(this._prevObj.groupName == undefined) && this._prevObj.groupName == _r2.groupName && !(this._prevObj.selected == true) && (_r2.selected == true || this._prevObj.tabIndex < _r2.tabIndex)) {
                                this._prevObj = _r2;
                            }
                        }
                    }
                    if (this._firstObj == undefined || _r2.tabIndex < this._firstObj.tabIndex && (_r2.groupName == undefined || this._firstObj.groupName == undefined || !(_r2.groupName == this._firstObj.groupName)) || !(this._firstObj.groupName == undefined) && this._firstObj.groupName == _r2.groupName && !(this._firstObj.selected == true) && (_r2.selected == true || _r2.tabIndex < this._firstObj.tabIndex)) {
                        this._firstObj = _r2;
                    }
                    if (this._lastObj == undefined || _r2.tabIndex > this._lastObj.tabIndex && (_r2.groupName == undefined || this._lastObj.groupName == undefined || !(_r2.groupName == this._lastObj.groupName)) || !(this._lastObj.groupName == undefined) && this._lastObj.groupName == _r2.groupName && !(this._lastObj.selected == true) && (_r2.selected == true || _r2.tabIndex > this._lastObj.tabIndex)) {
                        this._lastObj = _r2;
                    }
                }
                if (_r2.tabChildren) {
                    this.getTabCandidateFromChildren(_r2, index, groupName, dir, _r5 && firstChild);
                }
                _r5 = false;
            } else {
                if (_r2._parent == p && _r2.tabChildren == true && !(_r2._visible == false)) {
                    if (_r2 == this._lastTarget) {
                        while (_r2._searchKey == this._searchKey) {
                        }
                        _r2._searchKey = this._searchKey;
                        if (this._prevNode == undefined) {
                            _r3 = this._lastx;
                            _r7 = false;
                            while (_r3 != undefined) {
                                if (_r3 == _r2) {
                                    _r7 = true;
                                    break;
                                }
                                _r3 = _r3._parent;
                            }
                            if (_r7 == false) {
                                this._prevNode = this._lastx;
                            }
                        }
                        this._needPrev = false;
                        if (this._nextNode == undefined) {
                            this._nextIsNext = true;
                        }
                    } else {
                        if (!(!(_r2.focusManager == undefined) && _r2.focusManager._parent == _r2)) {
                            while (_r2._searchKey == this._searchKey) {
                            }
                            _r2._searchKey = this._searchKey;
                            this.getTabCandidateFromChildren(_r2, index, groupName, dir, _r5 && firstChild);
                        }
                    }
                    _r5 = false;
                }
            }
        }
        this._lastNode = this._lastx;
        if (lookup) {
            if (p._parent != undefined) {
                if (p != this._parent) {
                    if (this._prevNode == undefined && dir) {
                        this._needPrev = true;
                    } else {
                        if (this._nextNode == undefined && !dir) {
                            this._nextIsNext = false;
                        }
                    }
                    this._lastTarget = this._lastTarget._parent;
                    this.getTabCandidate(p._parent, index, groupName, dir, true);
                }
            }
        }
        /* leftover stack: ['null'] */
    };
    _r2.getTabCandidate = function (o, index, groupName, dir, firstChild) {
        _r2 = undefined;
        _r3 = true;
        if (o == this._parent) {
            _r2 = o;
            _r3 = false;
        } else {
            _r2 = o._parent;
            if (_r2 == undefined) {
                _r2 = o;
                _r3 = false;
            }
        }
        this.walkTree(_r2, index, groupName, dir, _r3, firstChild);
    };
    _r2.getTabCandidateFromChildren = function (o, index, groupName, dir, firstChild) {
        this.walkTree(o, index, groupName, dir, false, firstChild);
    };
    _r2.getFocusManagerFromObject = function (o) {
        while (o != undefined) {
            if (o.focusManager != undefined) {
                return o.focusManager;
            }
            o = o._parent;
        }
        return undefined;
    };
    _r2.tabHandler = function (Void) {
        this.bDrawFocus = true;
        _r5 = this.getSelectionFocus();
        _r4 = this.getActualFocus(_r5);
        if (_r4 != _r5) {
            _r5 = _r4;
        }
        if (this.getFocusManagerFromObject(_r5) != this) {
            _r5 == undefined;
        }
        if (_r5 == undefined) {
            _r5 = this.form;
        } else {
            if (_r5.tabIndex != undefined) {
                if (!(this._foundList == undefined) || !(this._foundList.tabIndex == _r5.tabIndex)) {
                    this._foundList = new Object();
                    this._foundList.tabIndex = _r5.tabIndex;
                }
                this._foundList[_r5._name] = _r5;
            }
        }
        _r3 = !(Key.isDown(16) == true);
        this._searchKey = getTimer();
        this._needPrev = true;
        this._nextIsNext = false;
        this._lastx = undefined;
        this._firstNode = undefined;
        this._lastNode = undefined;
        this._nextNode = undefined;
        this._prevNode = undefined;
        this._firstObj = undefined;
        this._lastObj = undefined;
        this._nextObj = undefined;
        this._prevObj = undefined;
        this._lastTarget = _r5;
        _r6 = _r5;
        this.getTabCandidate(_r6, _r5.tabIndex != undefined ? _r5.tabIndex : 0, _r5.groupName, _r3, true);
        _r2 = undefined;
        if (_r3) {
            if (this._nextObj != undefined) {
                _r2 = this._nextObj;
            } else {
                _r2 = this._firstObj;
            }
        } else {
            if (this._prevObj != undefined) {
                _r2 = this._prevObj;
            } else {
                _r2 = this._lastObj;
            }
        }
        if (_r2.tabIndex != _r5.tabIndex) {
            this._foundList = new Object();
            this._foundList.tabIndex = _r2.tabIndex;
            this._foundList[_r2._name] = _r2;
        } else {
            if (this._foundList == undefined) {
                this._foundList = new Object();
                this._foundList.tabIndex = _r2.tabIndex;
            }
            this._foundList[_r2._name] = _r2;
        }
        if (_r2 == undefined) {
            if (_r3 == false) {
                if (this._nextNode != undefined) {
                    _r2 = this._nextNode;
                } else {
                    _r2 = this._firstNode;
                }
            } else {
                if (this._prevNode == undefined || _r5 == this.form) {
                    _r2 = this._lastNode;
                } else {
                    _r2 = this._prevNode;
                }
            }
        }
        if (_r2 == undefined) {
            return undefined;
        }
        this.lastTabFocus = _r2;
        this.setFocus(_r2);
        if (_r2.emphasized != undefined) {
            if (this.defPushButton != undefined) {
                _r5 = this.defPushButton;
                this.defPushButton = _r2;
                _r5.emphasized = false;
                _r2.emphasized = true;
            }
        } else {
            if (!(this.defPushButton == undefined) && !(this.defPushButton == this.__defaultPushButton)) {
                _r5 = this.defPushButton;
                this.defPushButton = this.__defaultPushButton;
                _r5.emphasized = false;
                this.__defaultPushButton.__set__emphasized(true);
            }
        }
    };
    _r2.onKeyDown = function (Void) {
        mx.managers.SystemManager.idleFrames = 0;
        if (this.defaultPushButtonEnabled) {
            if (Key.getCode() == 13) {
                if (this.__get__defaultPushButton() != undefined) {
                    this.doLater(this, "sendDefaultPushButtonEvent");
                }
            }
        }
    };
    _r2.sendDefaultPushButtonEvent = function (Void) {
        this.defPushButton.dispatchEvent({type: "click"});
    };
    _r2.getMousedComponentFromChildren = function (x, y, o) {
        while ((_r0 = /*enum*/o) != null) {
            _r7 = _r0;
            _r2 = o[_r7];
            if (_r2._visible && _r2.enabled && _r2._parent == o && !(_r2._searchKey == this._searchKey)) {
                _r2._searchKey = this._searchKey;
                if (_r2.hitTest(x, y, true)) {
                    if (!(_r2.onPress == undefined) || !(_r2.onRelease == undefined)) {
                        do {
                        } while (!(null == null));
                        return _r2;
                    }
                    _r3 = this.getMousedComponentFromChildren(x, y, _r2);
                    if (_r3 != undefined) {
                        do {
                        } while (!(<UNDERFLOW> == null));
                        return _r3;
                    }
                    do {
                    } while (!(<UNDERFLOW> == null));
                    return _r2;
                }
            }
        }
        return undefined;
    };
    _r2.mouseActivate = function (Void) {
        if (!this.bNeedFocus) {
            return undefined;
        }
        this._searchKey = getTimer();
        _r2 = this.getMousedComponentFromChildren(this.lastMouse.x, this.lastMouse.y, this.form);
        if (_r2 instanceof mx.core.UIComponent) {
            return undefined;
        }
        _r2 = this.findFocusFromObject(_r2);
        if (_r2 == this.lastFocus) {
            return undefined;
        }
        if (_r2 == undefined) {
            this.doLater(this, "restoreFocus");
            return undefined;
        }
        _r3 = _r2.hscroll;
        if (_r3 != undefined) {
            _r6 = _r2.scroll;
            _r5 = _r2.background;
        }
        this.setFocus(_r2);
        _r4 = Selection;
        Selection.setSelection(_r4.lastBeginIndex, _r4.lastEndIndex);
        if (_r3 != undefined) {
            _r2.scroll = _r6;
            _r2.hscroll = _r3;
            _r2.background = _r5;
        }
    };
    _r2._onMouseDown = function (Void) {
        this.bDrawFocus = false;
        if (this.lastFocus != undefined) {
            this.lastFocus.drawFocus(false);
        }
        mx.managers.SystemManager.idleFrames = 0;
        _r3 = Selection;
        _r3.lastBeginIndex = Selection.getBeginIndex();
        _r3.lastEndIndex = Selection.getEndIndex();
        this.lastMouse.x = _root._xmouse;
        this.lastMouse.y = _root._ymouse;
        _root.localToGlobal(this.lastMouse);
    };
    _r2.onMouseUp = function (Void) {
        if (this._visible) {
            this.doLater(this, "mouseActivate");
        }
    };
    _r2.handleEvent = function (e) {
        if (e.type == "reveal") {
            mx.managers.SystemManager.activate(this.form);
        } else {
            mx.managers.SystemManager.deactivate(this.form);
        }
    };
    _r1.enableFocusManagement = function () {
        if (!mx.managers.FocusManager.initialized) {
            mx.managers.FocusManager.initialized = true;
            Object.registerClass("FocusManager", mx.managers.FocusManager);
            if (_root.focusManager == undefined) {
                mx.managers.DepthManager.highestDepth = mx.managers.DepthManager.highestDepth - 1;
                _root.createClassObject(mx.managers.FocusManager, "focusManager", mx.managers.DepthManager.highestDepth);
            }
        }
    };
    _r1.symbolName = "FocusManager";
    _r1.symbolOwner = mx.managers.FocusManager;
    _r1.version = "2.0.2.126";
    _r2.className = "FocusManager";
    _r2.bNeedFocus = false;
    _r2.bDrawFocus = false;
    _r2.defaultPushButtonEnabled = true;
    _r2.activated = true;
    _r1.initialized = false;
    _r1.UIObjectExtensionsDependency = mx.core.ext.UIObjectExtensions;
}
ASSetPropFlags(mx.managers.FocusManager.prototype, null, 1);
/* leftover stack: ['_r2.addProperty("defaultPushButton", _r2.__get__defaultPushButton, _r2.__set__defaultPushButton)', '_r2.addProperty("nextTabIndex", _r2.__get__nextTabIndex, function () {\n})'] */
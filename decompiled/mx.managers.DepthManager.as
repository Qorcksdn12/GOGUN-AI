if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers) {
    _global.mx.managers = new Object();
}
<UNDERFLOW>;
if (!_global.mx.managers.DepthManager) {
    mx.managers.DepthManager = _r1 = function () {
        MovieClip.prototype.createClassChildAtDepth = this.createClassChildAtDepth;
        MovieClip.prototype.createChildAtDepth = this.createChildAtDepth;
        MovieClip.prototype.setDepthTo = this.setDepthTo;
        MovieClip.prototype.setDepthAbove = this.setDepthAbove;
        MovieClip.prototype.setDepthBelow = this.setDepthBelow;
        MovieClip.prototype.findNextAvailableDepth = this.findNextAvailableDepth;
        MovieClip.prototype.shuffleDepths = this.shuffleDepths;
        MovieClip.prototype.getDepthByFlag = this.getDepthByFlag;
        MovieClip.prototype.buildDepthTable = this.buildDepthTable;
        _global.ASSetPropFlags(MovieClip.prototype, "createClassChildAtDepth", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "createChildAtDepth", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "setDepthTo", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "setDepthAbove", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "setDepthBelow", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "findNextAvailableDepth", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "shuffleDepths", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "getDepthByFlag", 1);
        _global.ASSetPropFlags(MovieClip.prototype, "buildDepthTable", 1);
    };
    _r2 = _r1.prototype;
    _r1.sortFunction = function (a, b) {
        if (a.getDepth() > b.getDepth()) {
            return 1;
        }
        return -1;
    };
    _r1.test = function (depth) {
        if (depth == mx.managers.DepthManager.reservedDepth) {
            return false;
        } else {
            return true;
        }
    };
    _r1.createClassObjectAtDepth = function (className, depthSpace, initObj) {
        _r1 = undefined;
        if ((_r0 = depthSpace) !== mx.managers.DepthManager.kCursor) {
            if (_r0 === mx.managers.DepthManager.kTooltip) goto L158;
        } else {
            _r1 = mx.managers.DepthManager.holder.createClassChildAtDepth(className, mx.managers.DepthManager.kTopmost, initObj);
            goto L236;
            _r1 = mx.managers.DepthManager.holder.createClassChildAtDepth(className, mx.managers.DepthManager.kTop, initObj);
            goto L236;
        }
        goto L236;
        return _r1;
    };
    _r1.createObjectAtDepth = function (linkageName, depthSpace, initObj) {
        _r1 = undefined;
        if ((_r0 = depthSpace) !== mx.managers.DepthManager.kCursor) {
            if (_r0 === mx.managers.DepthManager.kTooltip) goto L158;
        } else {
            _r1 = mx.managers.DepthManager.holder.createChildAtDepth(linkageName, mx.managers.DepthManager.kTopmost, initObj);
            goto L236;
            _r1 = mx.managers.DepthManager.holder.createChildAtDepth(linkageName, mx.managers.DepthManager.kTop, initObj);
            goto L236;
        }
        goto L236;
        return _r1;
    };
    _r2.createClassChildAtDepth = function (className, depthFlag, initObj) {
        if (this._childCounter == undefined) {
            this._childCounter = 0;
        }
        _r3 = this.buildDepthTable();
        _r2 = this.getDepthByFlag(depthFlag, _r3);
        _r6 = "down";
        if (depthFlag == mx.managers.DepthManager.kBottom) {
            _r6 = "up";
        }
        _r5 = undefined;
        if (_r3[_r2] != undefined) {
            _r5 = _r2;
            _r2 = this.findNextAvailableDepth(_r2, _r3, _r6);
        }
        this._childCounter = this._childCounter + 1;
        _r4 = this.createClassObject(className, "depthChild" + this._childCounter, _r2, initObj);
        if (_r5 != undefined) {
            _r3[_r2] = _r4;
            this.shuffleDepths(_r4, _r5, _r3, _r6);
        }
        if (depthFlag == mx.managers.DepthManager.kTopmost) {
            _r4._topmost = true;
        }
        return _r4;
    };
    _r2.createChildAtDepth = function (linkageName, depthFlag, initObj) {
        if (this._childCounter == undefined) {
            this._childCounter = 0;
        }
        _r3 = this.buildDepthTable();
        _r2 = this.getDepthByFlag(depthFlag, _r3);
        _r6 = "down";
        if (depthFlag == mx.managers.DepthManager.kBottom) {
            _r6 = "up";
        }
        _r5 = undefined;
        if (_r3[_r2] != undefined) {
            _r5 = _r2;
            _r2 = this.findNextAvailableDepth(_r2, _r3, _r6);
        }
        this._childCounter = this._childCounter + 1;
        _r4 = this.createObject(linkageName, "depthChild" + this._childCounter, _r2, initObj);
        if (_r5 != undefined) {
            _r3[_r2] = _r4;
            this.shuffleDepths(_r4, _r5, _r3, _r6);
        }
        if (depthFlag == mx.managers.DepthManager.kTopmost) {
            _r4._topmost = true;
        }
        return _r4;
    };
    _r2.setDepthTo = function (depthFlag) {
        _r2 = this._parent.buildDepthTable();
        _r3 = this._parent.getDepthByFlag(depthFlag, _r2);
        if (_r2[_r3] != undefined) {
            this.shuffleDepths(this, _r3, _r2, undefined);
        } else {
            this.swapDepths(_r3);
        }
        if (depthFlag == mx.managers.DepthManager.kTopmost) {
            this._topmost = true;
        } else {
            delete this._topmost;
        }
    };
    _r2.setDepthAbove = function (targetInstance) {
        if (targetInstance._parent != this._parent) {
            return undefined;
        }
        _r2 = targetInstance.getDepth() + 1;
        _r3 = this._parent.buildDepthTable();
        if (!(_r3[_r2] == undefined) && this.getDepth() < _r2) {
            _r2 = _r2 - 1;
        }
        if (_r2 > mx.managers.DepthManager.highestDepth) {
            _r2 = mx.managers.DepthManager.highestDepth;
        }
        if (_r2 == mx.managers.DepthManager.highestDepth) {
            this._parent.shuffleDepths(this, _r2, _r3, "down");
        } else {
            if (_r3[_r2] != undefined) {
                this._parent.shuffleDepths(this, _r2, _r3, undefined);
            } else {
                this.swapDepths(_r2);
            }
        }
    };
    _r2.setDepthBelow = function (targetInstance) {
        if (targetInstance._parent != this._parent) {
            return undefined;
        }
        _r6 = targetInstance.getDepth() - 1;
        _r3 = this._parent.buildDepthTable();
        if (!(_r3[_r6] == undefined) && this.getDepth() > _r6) {
            _r6 = _r6 + 1;
        }
        _r4 = mx.managers.DepthManager.lowestDepth + mx.managers.DepthManager.numberOfAuthortimeLayers;
        _r5 = undefined;
        while ((_r0 = /*enum*/_r3) != null) {
            _r5 = _r0;
            _r2 = _r3[_r5];
            if (_r2._parent != undefined) {
                _r4 = Math.min(_r4, _r2.getDepth());
            }
        }
        if (_r6 < _r4) {
            _r6 = _r4;
        }
        if (_r6 == _r4) {
            this._parent.shuffleDepths(this, _r6, _r3, "up");
        } else {
            if (_r3[_r6] != undefined) {
                this._parent.shuffleDepths(this, _r6, _r3, undefined);
            } else {
                this.swapDepths(_r6);
            }
        }
        /* leftover stack: ['null'] */
    };
    _r2.findNextAvailableDepth = function (targetDepth, depthTable, direction) {
        _r5 = mx.managers.DepthManager.lowestDepth + mx.managers.DepthManager.numberOfAuthortimeLayers;
        if (targetDepth < _r5) {
            targetDepth = _r5;
        }
        if (depthTable[targetDepth] == undefined) {
            return targetDepth;
        }
        _r2 = targetDepth;
        _r1 = targetDepth;
        if (direction == "down") {
            while (depthTable[_r1] != undefined) {
                _r1 = _r1 - 1;
            }
            return _r1;
        }
        while (depthTable[_r2] != undefined) {
            _r2 = _r2 + 1;
        }
        return _r2;
    };
    _r2.shuffleDepths = function (subject, targetDepth, depthTable, direction) {
        _r9 = mx.managers.DepthManager.lowestDepth + mx.managers.DepthManager.numberOfAuthortimeLayers;
        _r8 = _r9;
        _r5 = undefined;
        while ((_r0 = /*enum*/depthTable) != null) {
            _r5 = _r0;
            _r7 = depthTable[_r5];
            if (_r7._parent != undefined) {
                _r9 = Math.min(_r9, _r7.getDepth());
            }
        }
        if (direction == undefined) {
            if (subject.getDepth() > targetDepth) {
                direction = "up";
            } else {
                direction = "down";
            }
        }
        _r1 = new Array();
        while ((_r0 = /*enum*/depthTable) != null) {
            _r5 = _r0;
            _r7 = depthTable[_r5];
            if (_r7._parent != undefined) {
                _r1.push(_r7);
            }
        }
        _r1.sort(mx.managers.DepthManager.sortFunction);
        if (direction == "up") {
            _r3 = undefined;
            _r11 = undefined;
            while (_r1.length > 0) {
                _r3 = _r1.pop();
                if (_r3 == subject) {
                    break;
                }
            }
            while (_r1.length > 0) {
                _r11 = subject.getDepth();
                _r3 = _r1.pop();
                _r4 = _r3.getDepth();
                if (_r11 > _r4 + 1) {
                    if (_r4 >= 0) {
                        subject.swapDepths(_r4 + 1);
                    } else {
                        if (_r11 > _r8 && _r4 < _r8) {
                            subject.swapDepths(_r8);
                        }
                    }
                }
                subject.swapDepths(_r3);
                if (_r4 == targetDepth) {
                    break;
                }
            }
        } else {
            if (direction == "down") {
                _r3 = undefined;
                while (_r1.length > 0) {
                    _r3 = _r1.shift();
                    if (_r3 == subject) {
                        break;
                    }
                }
                while (_r1.length > 0) {
                    _r11 = _r3.getDepth();
                    _r3 = _r1.shift();
                    _r4 = _r3.getDepth();
                    if (_r11 < _r4 - 1 && _r4 > 0) {
                        subject.swapDepths(_r4 - 1);
                    }
                    subject.swapDepths(_r3);
                    if (_r4 == targetDepth) {
                        break;
                    }
                }
            }
        }
        /* leftover stack: ['null', 'null'] */
    };
    _r2.getDepthByFlag = function (depthFlag, depthTable) {
        _r2 = 0;
        if (depthFlag == mx.managers.DepthManager.kTop || depthFlag == mx.managers.DepthManager.kNotopmost) {
            _r5 = 0;
            _r7 = false;
            _r8 = undefined;
            while ((_r0 = /*enum*/depthTable) != null) {
                _r8 = _r0;
                _r9 = depthTable[_r8];
                _r3 = typeof _r9;
                if (_r3 == "movieclip" || _r3 == "object" && !(_r9.__getTextFormat == undefined)) {
                    if (_r9.getDepth() <= mx.managers.DepthManager.highestDepth) {
                        if (!_r9._topmost) {
                            _r2 = Math.max(_r2, _r9.getDepth());
                        } else {
                            if (!_r7) {
                                _r5 = _r9.getDepth();
                                _r7 = true;
                            } else {
                                _r5 = Math.min(_r5, _r9.getDepth());
                            }
                        }
                    }
                }
            }
            _r2 = _r2 + 20;
            if (_r7) {
                if (_r2 >= _r5) {
                    _r2 = _r5 - 1;
                }
            }
        } else {
            if (depthFlag == mx.managers.DepthManager.kBottom) {
                while ((_r0 = /*enum*/depthTable) != null) {
                    _r8 = _r0;
                    _r9 = depthTable[_r8];
                    _r3 = typeof _r9;
                    if (_r3 == "movieclip" || _r3 == "object" && !(_r9.__getTextFormat == undefined)) {
                        if (_r9.getDepth() <= mx.managers.DepthManager.highestDepth) {
                            _r2 = Math.min(_r2, _r9.getDepth());
                        }
                    }
                }
                _r2 = _r2 - 20;
            } else {
                if (depthFlag == mx.managers.DepthManager.kTopmost) {
                    while ((_r0 = /*enum*/depthTable) != null) {
                        _r8 = _r0;
                        _r9 = depthTable[_r8];
                        _r3 = typeof _r9;
                        if (_r3 == "movieclip" || _r3 == "object" && !(_r9.__getTextFormat == undefined)) {
                            if (_r9.getDepth() <= mx.managers.DepthManager.highestDepth) {
                                _r2 = Math.max(_r2, _r9.getDepth());
                            }
                        }
                    }
                    _r2 = _r2 + 100;
                }
            }
        }
        if (_r2 >= mx.managers.DepthManager.highestDepth) {
            _r2 = mx.managers.DepthManager.highestDepth;
        }
        _r6 = mx.managers.DepthManager.lowestDepth + mx.managers.DepthManager.numberOfAuthortimeLayers;
        while ((_r0 = /*enum*/depthTable) != null) {
            _r9 = _r0;
            _r4 = depthTable[_r9];
            if (_r4._parent != undefined) {
                _r6 = Math.min(_r6, _r4.getDepth());
            }
        }
        if (_r2 <= _r6) {
            _r2 = _r6;
        }
        return _r2;
        /* leftover stack: ['null', 'null', 'null', 'null'] */
    };
    _r2.buildDepthTable = function (Void) {
        _r5 = new Array();
        _r4 = undefined;
        while ((_r0 = /*enum*/this) != null) {
            _r4 = _r0;
            _r2 = this[_r4];
            _r3 = typeof _r2;
            if (_r3 == "movieclip" || _r3 == "object" && !(_r2.__getTextFormat == undefined)) {
                if (_r2._parent == this) {
                    _r5[_r2.getDepth()] = _r2;
                }
            }
        }
        return _r5;
        /* leftover stack: ['null'] */
    };
    _r1.reservedDepth = 1048575;
    _r1.highestDepth = 1048574;
    _r1.lowestDepth = -16383;
    _r1.numberOfAuthortimeLayers = 383;
    _r1.kCursor = 101;
    _r1.kTooltip = 102;
    _r1.kTop = 201;
    _r1.kBottom = 202;
    _r1.kTopmost = 203;
    _r1.kNotopmost = 204;
    _r1.holder = _root.createEmptyMovieClip("reserved", mx.managers.DepthManager.reservedDepth);
    _r1.__depthManager = new mx.managers.DepthManager();
}
ASSetPropFlags(mx.managers.DepthManager.prototype, null, 1);
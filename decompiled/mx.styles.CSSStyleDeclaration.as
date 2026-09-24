if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles) {
    _global.mx.styles = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles.CSSStyleDeclaration) {
    mx.styles.CSSStyleDeclaration = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r2.__getTextFormat = function (tf, bAll) {
        _r5 = false;
        if (this._tf != undefined) {
            _r2 = undefined;
            while ((_r0 = /*enum*/mx.styles.StyleManager.TextFormatStyleProps) != null) {
                _r2 = _r0;
                if (bAll || mx.styles.StyleManager.TextFormatStyleProps[_r2]) {
                    if (tf[_r2] == undefined) {
                        _r3 = this._tf[_r2];
                        if (_r3 != undefined) {
                            tf[_r2] = _r3;
                        } else {
                            _r5 = true;
                        }
                    }
                }
            }
        } else {
            _r5 = true;
        }
        return _r5;
        /* leftover stack: ['null'] */
    };
    _r2.getStyle = function (styleProp) {
        _r2 = this[styleProp];
        _r3 = mx.styles.StyleManager.getColorName(_r2);
        return _r3 != undefined ? _r3 : _r2;
    };
    _r1.classConstruct = function () {
        mx.styles.CSSTextStyles.addTextStyles(mx.styles.CSSStyleDeclaration.prototype, true);
        return true;
    };
    _r1.classConstructed = mx.styles.CSSStyleDeclaration.classConstruct();
    _r1.CSSTextStylesDependency = mx.styles.CSSTextStyles;
}
ASSetPropFlags(mx.styles.CSSStyleDeclaration.prototype, null, 1);
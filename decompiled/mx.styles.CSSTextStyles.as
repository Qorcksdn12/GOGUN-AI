if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles) {
    _global.mx.styles = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles.CSSTextStyles) {
    mx.styles.CSSTextStyles = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.addTextStyles = function (o, bColor) {
        o.addProperty("textAlign", function () {
            return this._tf.align;
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.align = x;
        });
        o.addProperty("fontWeight", function () {
            return this._tf.bold == undefined ? undefined : (!this._tf.bold ? "none" : "bold");
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.bold = x == "bold";
        });
        if (bColor) {
            o.addProperty("color", function () {
                return this._tf.color;
            }, function (x) {
                if (this._tf == undefined) {
                    this._tf = new TextFormat();
                }
                this._tf.color = x;
            });
        }
        o.addProperty("fontFamily", function () {
            return this._tf.font;
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.font = x;
        });
        o.addProperty("textIndent", function () {
            return this._tf.indent;
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.indent = x;
        });
        o.addProperty("fontStyle", function () {
            return this._tf.italic == undefined ? undefined : (!this._tf.italic ? "none" : "italic");
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.italic = x == "italic";
        });
        o.addProperty("marginLeft", function () {
            return this._tf.leftMargin;
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.leftMargin = x;
        });
        o.addProperty("marginRight", function () {
            return this._tf.rightMargin;
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.rightMargin = x;
        });
        o.addProperty("fontSize", function () {
            return this._tf.size;
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.size = x;
        });
        o.addProperty("textDecoration", function () {
            return this._tf.underline == undefined ? undefined : (!this._tf.underline ? "none" : "underline");
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.underline = x == "underline";
        });
        o.addProperty("embedFonts", function () {
            return this._tf.embedFonts;
        }, function (x) {
            if (this._tf == undefined) {
                this._tf = new TextFormat();
            }
            this._tf.embedFonts = x;
        });
    };
}
ASSetPropFlags(mx.styles.CSSTextStyles.prototype, null, 1);
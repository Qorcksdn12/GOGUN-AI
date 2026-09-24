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
if (!_global.mx.skins.halo.Defaults) {
    mx.skins.halo.Defaults = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.setThemeDefaults = function () {
        _r2 = _global.style;
        _r2.themeColor = 8453965;
        _r2.disabledColor = 8684164;
        _r2.modalTransparency = 0;
        _r2.filled = true;
        _r2.stroked = true;
        _r2.strokeWidth = 1;
        _r2.strokeColor = 0;
        _r2.fillColor = 16777215;
        _r2.repeatInterval = 35;
        _r2.repeatDelay = 500;
        _r2.fontFamily = "_sans";
        _r2.fontSize = 12;
        _r2.selectionColor = 13500353;
        _r2.rollOverColor = 14942166;
        _r2.useRollOver = true;
        _r2.backgroundDisabledColor = 14540253;
        _r2.selectionDisabledColor = 14540253;
        _r2.selectionDuration = 200;
        _r2.openDuration = 250;
        _r2.borderStyle = "inset";
        _r2.color = 734012;
        _r2.textSelectedColor = 24371;
        _r2.textRollOverColor = 2831164;
        _r2.textDisabledColor = 16777215;
        _r2.vGridLines = true;
        _r2.hGridLines = false;
        _r2.vGridLineColor = 6710886;
        _r2.hGridLineColor = 6710886;
        _r2.headerColor = 15395562;
        _r2.indentation = 17;
        _r2.folderOpenIcon = "TreeFolderOpen";
        _r2.folderClosedIcon = "TreeFolderClosed";
        _r2.defaultLeafIcon = "TreeNodeIcon";
        _r2.disclosureOpenIcon = "TreeDisclosureOpen";
        _r2.disclosureClosedIcon = "TreeDisclosureClosed";
        _r2.popupDuration = 150;
        _r2.todayColor = 6710886;
        _global.styles.ScrollSelectList = _r0 = new mx.styles.CSSStyleDeclaration();
        _r2 = _r0;
        _r2.backgroundColor = 16777215;
        _r2.borderColor = 13290186;
        _r2.borderStyle = "inset";
        _global.styles.ComboBox = _r0 = new mx.styles.CSSStyleDeclaration();
        _r2 = _r0;
        _r2.borderStyle = "inset";
        _global.styles.NumericStepper = _r0 = new mx.styles.CSSStyleDeclaration();
        _r2 = _r0;
        _r2.textAlign = "center";
        _global.styles.RectBorder = _r0 = new mx.styles.CSSStyleDeclaration();
        _r2 = _r0;
        _r2.borderColor = 14015965;
        _r2.buttonColor = 7305079;
        _r2.shadowColor = 15658734;
        _r2.highlightColor = 12897484;
        _r2.shadowCapColor = 14015965;
        _r2.borderCapColor = 9542041;
        _r4 = new Object();
        _r4.borderColor = 16711680;
        _r4.buttonColor = 16711680;
        _r4.shadowColor = 16711680;
        _r4.highlightColor = 16711680;
        _r4.shadowCapColor = 16711680;
        _r4.borderCapColor = 16711680;
        mx.core.UIComponent.prototype.origBorderStyles = _r4;
        _r3 = undefined;
        _global.styles.TextInput = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.backgroundColor = 16777215;
        _r3.borderStyle = "inset";
        _global.styles.TextArea = _global.styles.TextInput;
        _global.styles.Window = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.borderStyle = "default";
        _global.styles.windowStyles = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.fontWeight = "bold";
        _global.styles.dataGridStyles = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.fontWeight = "bold";
        _global.styles.Alert = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.borderStyle = "alert";
        _global.styles.ScrollView = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.borderStyle = "inset";
        _global.styles.View = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.borderStyle = "none";
        _global.styles.ProgressBar = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.color = 11187123;
        _r3.fontWeight = "bold";
        _global.styles.AccordionHeader = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.fontWeight = "bold";
        _r3.fontSize = "11";
        _global.styles.Accordion = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.borderStyle = "solid";
        _r3.backgroundColor = 16777215;
        _r3.borderColor = 9081738;
        _r3.headerHeight = 22;
        _r3.marginBottom = _r0 = -1;
        _r3.marginTop = _r0 = _r0;
        _r3.marginRight = _r0 = _r0;
        _r3.marginLeft = _r0;
        _r3.verticalGap = -1;
        _global.styles.DateChooser = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.borderColor = 9542041;
        _r3.headerColor = 16777215;
        _global.styles.CalendarLayout = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.fontSize = 10;
        _r3.textAlign = "right";
        _r3.color = 2831164;
        _global.styles.WeekDayStyle = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.fontWeight = "bold";
        _r3.fontSize = 11;
        _r3.textAlign = "center";
        _r3.color = 2831164;
        _global.styles.TodayStyle = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.color = 16777215;
        _global.styles.HeaderDateText = _r0 = new mx.styles.CSSStyleDeclaration();
        _r3 = _r0;
        _r3.fontSize = 12;
        _r3.fontWeight = "bold";
        _r3.textAlign = "center";
    };
    _r2.drawRoundRect = function (x, y, w, h, r, c, alpha, rot, gradient, ratios) {
        if (typeof r == "object") {
            _r18 = r.br;
            _r16 = r.bl;
            _r15 = r.tl;
            _r10 = r.tr;
        } else {
            _r18 = _r16 = _r15 = _r10 = r;
        }
        if (typeof c == "object") {
            if (typeof alpha != "object") {
                _r9 = [alpha, alpha];
            } else {
                _r9 = alpha;
            }
            if (ratios == undefined) {
                ratios = [0, 255];
            }
            _r14 = h * 0.7;
            if (typeof rot != "object") {
                _r11 = {matrixType: "box", x: 0 - _r14, y: _r14, w: w * 2, h: h * 4, r: rot * 0.017453293};
            } else {
                _r11 = rot;
            }
            if (gradient == "radial") {
                this.beginGradientFill("radial", c, _r9, ratios, _r11);
            } else {
                this.beginGradientFill("linear", c, _r9, ratios, _r11);
            }
        } else {
            if (c != undefined) {
                this.beginFill(c, alpha);
            }
        }
        r = _r18;
        _r13 = r - r * 0.707106781;
        _r12 = r - r * 0.414213562;
        this.moveTo(x + w, y + h - r);
        this.lineTo(x + w, y + h - r);
        this.curveTo(x + w, y + h - _r12, x + w - _r13, y + h - _r13);
        this.curveTo(x + w - _r12, y + h, x + w - r, y + h);
        r = _r16;
        _r13 = r - r * 0.707106781;
        _r12 = r - r * 0.414213562;
        this.lineTo(x + r, y + h);
        this.curveTo(x + _r12, y + h, x + _r13, y + h - _r13);
        this.curveTo(x, y + h - _r12, x, y + h - r);
        r = _r15;
        _r13 = r - r * 0.707106781;
        _r12 = r - r * 0.414213562;
        this.lineTo(x, y + r);
        this.curveTo(x, y + _r12, x + _r13, y + _r13);
        this.curveTo(x + _r12, y, x + r, y);
        r = _r10;
        _r13 = r - r * 0.707106781;
        _r12 = r - r * 0.414213562;
        this.lineTo(x + w - r, y);
        this.curveTo(x + w - _r12, y, x + w - _r13, y + _r13);
        this.curveTo(x + w, y + _r12, x + w, y + r);
        this.lineTo(x + w, y + h - r);
        if (c != undefined) {
            this.endFill();
        }
    };
    _r1.classConstruct = function () {
        mx.core.ext.UIObjectExtensions.Extensions();
        mx.skins.halo.Defaults.setThemeDefaults();
        mx.core.UIObject.prototype.drawRoundRect = mx.skins.halo.Defaults.prototype.drawRoundRect;
        return true;
    };
    _r1.classConstructed = mx.skins.halo.Defaults.classConstruct();
    _r1.CSSStyleDeclarationDependency = mx.styles.CSSStyleDeclaration;
    _r1.UIObjectExtensionsDependency = mx.core.ext.UIObjectExtensions;
    _r1.UIObjectDependency = mx.core.UIObject;
}
ASSetPropFlags(mx.skins.halo.Defaults.prototype, null, 1);
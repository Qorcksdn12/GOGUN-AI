if (!_global.mx) {
    _global.mx = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles) {
    _global.mx.styles = new Object();
}
<UNDERFLOW>;
if (!_global.mx.styles.StyleManager) {
    mx.styles.StyleManager = _r1 = function () {
    };
    _r2 = _r1.prototype;
    _r1.registerInheritingStyle = function (styleName) {
        mx.styles.StyleManager.inheritingStyles[styleName] = true;
    };
    _r1.isInheritingStyle = function (styleName) {
        return mx.styles.StyleManager.inheritingStyles[styleName] == true;
    };
    _r1.registerColorStyle = function (styleName) {
        mx.styles.StyleManager.colorStyles[styleName] = true;
    };
    _r1.isColorStyle = function (styleName) {
        return mx.styles.StyleManager.colorStyles[styleName] == true;
    };
    _r1.registerColorName = function (colorName, colorValue) {
        mx.styles.StyleManager.colorNames[colorName] = colorValue;
    };
    _r1.isColorName = function (colorName) {
        return !(mx.styles.StyleManager.colorNames[colorName] == undefined);
    };
    _r1.getColorName = function (colorName) {
        return mx.styles.StyleManager.colorNames[colorName];
    };
    _r1.inheritingStyles = {color: true, direction: true, fontFamily: true, fontSize: true, fontStyle: true, fontWeight: true, textAlign: true, textIndent: true};
    _r1.colorStyles = {barColor: true, trackColor: true, borderColor: true, buttonColor: true, color: true, dateHeaderColor: true, dateRollOverColor: true, disabledColor: true, fillColor: true, highlightColor: true, scrollTrackColor: true, selectedDateColor: true, shadowColor: true, strokeColor: true, symbolBackgroundColor: true, symbolBackgroundDisabledColor: true, symbolBackgroundPressedColor: true, symbolColor: true, symbolDisabledColor: true, themeColor: true, todayIndicatorColor: true, shadowCapColor: true, borderCapColor: true, focusColor: true};
    _r1.colorNames = {black: 0, white: 16777215, red: 16711680, green: 65280, blue: 255, magenta: 16711935, yellow: 16776960, cyan: 65535, haloGreen: 8453965, haloBlue: 2881013, haloOrange: 16761344};
    _r1.TextFormatStyleProps = {font: true, size: true, color: true, leftMargin: false, rightMargin: false, italic: true, bold: true, align: true, indent: true, underline: false, embedFonts: false};
    _r1.TextStyleMap = {textAlign: true, fontWeight: true, color: true, fontFamily: true, textIndent: true, fontStyle: true, lineHeight: true, marginLeft: true, marginRight: true, fontSize: true, textDecoration: true, embedFonts: true};
}
ASSetPropFlags(mx.styles.StyleManager.prototype, null, 1);
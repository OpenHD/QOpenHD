import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// From https://doc.qt.io/qt-5/qml-qtquick-controls2-spinbox.html
// Modified a bit for easier use
GgSpinBox {

    // Min,max,default in double space
    property double m_default_value: 0.00
    property double m_min_value: 0.0
    property double m_max_value: 3.0

    // NOTE:
    // Overwrite onRealValueChanged: { } to write the value to settings

    id: spinBox
    from: decimalToInt(m_min_value)
    value: decimalToInt(m_default_value)
    to: decimalToInt(m_max_value)
    stepSize: 1
    editable: true

    property int decimals: 2
    readonly property int decimalFactor: Math.pow(10, decimals)
    property real realValue: value / decimalFactor

    function decimalToInt(decimal) {
        return decimal * decimalFactor
    }
    function intToDecimal(int_val){
        return Number(value / decimalFactor);
    }

    validator: DoubleValidator {
        bottom: Math.min(spinBox.from, spinBox.to)
        top:  Math.max(spinBox.from, spinBox.to)
        decimals: spinBox.decimals
        notation: DoubleValidator.StandardNotation
    }

    textFromValue: function(value, locale) {
        return Number(value / decimalFactor).toLocaleString(locale, 'f', spinBox.decimals)
    }

    valueFromText: function(text, locale) {
        return Math.round(Number.fromLocaleString(locale, text) * decimalFactor)
    }

    onValueChanged: {
        var dec_value=intToDecimal(value)
        //console.log("Decimal spin box value changed to:"+dec_value+" ("+value+")")
    }
}

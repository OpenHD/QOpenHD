import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtQuick.Shapes 1.15

Button{
    id: triangle_button
    property bool m_is_enabled: false

    property bool m_point_right: true

    property color m_fill_color: "green"

    //text: "L"
    text: ""

    background: Item{
        width: triangle_button.width
        height: triangle_button.height
        Rectangle{
            width: parent.width
            height: parent.height
            color: {
                if(triangle_button.hovered){
                    if(m_is_enabled){
                        return "gray";
                    }
                    return "red";
                }
                return "transparent";
            }
        }
        Shape {
            anchors.fill: parent
            anchors.margins: 12
            id: shape
            antialiasing: true
            opacity: m_is_enabled ? 1.0 : 0.3;
            ShapePath {
                fillColor: {
                    return "white"
                }
                strokeWidth: 0
                strokeColor: fillColor
                startX: m_point_right ? 0 : shape.width
                PathLine { x: (m_point_right ? 0 : shape.width) ; y: 0 }
                PathLine { x: (m_point_right ? shape.width : 0) ; y: shape.height/2 }
                PathLine { x: (m_point_right ? 0 : shape.width) ; y: shape.height }
            }
        }
    }
}

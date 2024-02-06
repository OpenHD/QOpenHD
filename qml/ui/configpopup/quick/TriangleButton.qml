import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtQuick.Shapes 1.15

Button{
    id: triangle_button
    property bool m_is_active: false

    property bool m_point_right: true

    property color m_fill_color: "green"

    background:  Shape {
        width: triangle_button.width
        height: triangle_button.height
        id: shape
        antialiasing: true
        ShapePath {
            fillColor: m_fill_color
            strokeWidth: 0
            startX: m_point_right ? 0 : shape.width
            PathLine { x: (m_point_right ? 0 : shape.width) ; y: 0 }
            PathLine { x: (m_point_right ? shape.width : 0) ; y: shape.height/2 }
            PathLine { x: (m_point_right ? 0 : shape.width) ; y: shape.height }
        }
    }
}

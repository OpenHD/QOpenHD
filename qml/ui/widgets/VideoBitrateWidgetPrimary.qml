import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

VideoBitrateWidgetGeneric{
    visible: settings.show_bitrate && settings.show_widgets

    m_is_for_primary_camera: true


}

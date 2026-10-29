import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

VideoBitrateWidgetGeneric{
    m_is_for_primary_camera: false
    // Follow the confirmed secondary stream state, including explicit disable.
    visible: settings.show_bitrate && settings.secondary_camera_available

    m_show_button_quick_switch: _qopenhd.is_linux() && !_qopenhd.is_platform_rpi()
}

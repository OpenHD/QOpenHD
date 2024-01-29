import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

VideoBitrateWidgetGeneric{
    m_is_for_primary_camera: false
    // Also show it if air has a seconary cam
    visible: (settings.show_bitrate && settings.dev_qopenhd_n_cameras>1) || (settings.show_bitrate && _ohdSystemAir.dirty_air_has_secondary_cam)
}

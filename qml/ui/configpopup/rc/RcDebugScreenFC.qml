import QtQuick 2.12
RcChannelsView {
    title: qsTr("FLIGHT CONTROLLER CHANNELS")
    description: qsTr("RC channel values reported by ArduPilot over MAVLink at its debug update rate")
    channelModel: _rcchannelsmodelfc
}

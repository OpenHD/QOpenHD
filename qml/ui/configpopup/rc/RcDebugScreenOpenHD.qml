import QtQuick 2.12
RcChannelsView {
    title: qsTr("OPENHD RC CHANNELS")
    description: qsTr("Joystick values read by the ground unit and forwarded over the OpenHD link")
    channelModel: _rcchannelsmodelground
}

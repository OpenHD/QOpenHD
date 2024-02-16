import QtQuick 2.0

SideBarBasePanel{
    override_title: "Link"


    function takeover_control(){
        edit_frequency_element.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5

        EditFrequencyElement{
            id: edit_frequency_element
            onGoto_previous: {
                sidebar.regain_control_on_sidebar_stack()
            }
            onGoto_next: {
                edit_channel_width_element.takeover_control()
            }
        }

        EditChannelWidthElement{
            id: edit_channel_width_element
            onGoto_previous: {
                edit_frequency_element.takeover_control();
            }
            onGoto_next: {
                edit_rate_element.takeover_control()
            }
        }

        EditRateElement{
            id: edit_rate_element
            onGoto_previous: {
               edit_channel_width_element.takeover_control()
            }
            onGoto_next: {
                sidebar.regain_control_on_sidebar_stack()
            }
        }
    }
}

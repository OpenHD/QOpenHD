import QtQuick 2.12

Item {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 120
    anchors.rightMargin: 20
    width: 100
    height: 30

    // 0 - all okay
    // 1 - warning, soon overheating
    // 2 - error, overheating protection on (Video disabled)
    property int m_x20_state: {
        return 1;
        if(_ohdSystemAir.video_disabled_due_to_overheating<0){
            return 0; // Unknown
        }
        if(_ohdSystemAir.video_disabled_due_to_overheating==1){
            return 2;
        }
        if(_ohdSystemAir.curr_soc_temp_degree>=71){
            return 1;
        }
        return 0;
    }

    Rectangle{
        anchors.fill: parent
        color: "black"
        opacity: 0.8;
        visible: m_x20_state>0;
        border.width: 2
        border.color: text_field.color
    }

    Text{
        id: text_field
        visible: m_x20_state>0;
        anchors.fill: parent
        text: {
            if(m_x20_state==0)return "";
            if(m_x20_state==1)return "\uf2c7"+" \uf46a"+" !"
            return "\uf2c7"+" \uf46a"+" \uf4e2"
        }
        color: {
            if(m_x20_state==1)return "orange";
            if(m_x20_state==2)return "red";
            return "white";
        }
        font.pixelSize: 16
        font.family: "Font Awesome 5 Free"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        style: Text.Outline
        styleColor: "white"
    }
}

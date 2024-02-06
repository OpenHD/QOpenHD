import QtQuick 2.0


Rectangle{
    id: go_back_element
    width: parent.width
    height: 50
    color: "blue"
    opacity:go_back_element.focus ? 1.0 : 0.4;
    Text{
         text: "BACK"
         color: "white"
         verticalAlignment: Qt.AlignVCenter
         horizontalAlignment: Qt.AlignHCenter
    }

    Keys.onPressed: (event)=> {
                        console.log("Go back element key was pressed:"+event);
                        if(event.key == Qt.Key_Left){
                           // Go back to the
                            settings_form.gain_focus();
                        }
                    }
}

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    visible: settings.show_horizon

    widgetIdentifier: "horizon_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView{

        contentHeight: horizonSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            id: horizonSettingsColumn
            spacing:0
            clip: true

            Item {
                width: 230
                height: 32
                Text {
                    text: "Opacity"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.horizon_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_opacity = horizon_opacity_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: "Size"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_size_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.horizon_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_size = horizon_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: "Invert Pitch"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    checked: settings.horizon_invert_pitch
                    onCheckedChanged: settings.horizon_invert_pitch = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: invertTitle
                    text: "Invert Roll"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    checked: settings.horizon_invert_roll
                    onCheckedChanged: settings.horizon_invert_roll = checked
                }
            }
            Item {
                width: 230
                height: 32
                visible: true
                Text {
                    text: "Spacing"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_spacing_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.horizon_ladder_spacing
                    to: 20
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_ladder_spacing = horizon_spacing_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: "Show Ladder"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 12
                    anchors.right: parent.right
                    checked: settings.show_horizon_ladder
                    onCheckedChanged: settings.show_horizon_ladder = checked
                }
            }
        }
    }


    function getHorizonPitch(){
        var raw_pitch= settings.horizon_invert_pitch ? -OpenHD.pitch : OpenHD.pitch;

        //in all the rectangles is a constant of "10" and each line represents 10 degrees
        var ratio= settings.horizon_ladder_spacing

        return ratio * raw_pitch
    }

    Item {
        id: widgetInner
        height: 2
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        opacity: settings.horizon_opacity

        antialiasing: true

        transformOrigin: Item.Center

        rotation: settings.horizon_invert_roll ? OpenHD.roll : -OpenHD.roll


        transform:
            Translate {
                x: Item.Center
                y: { getHorizonPitch() }
            }

        Item {
            id:mainHorizon
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            transform: Scale { origin.x: 125; origin.y: 0; xScale: settings.horizon_size; yScale: 1}

            Rectangle {
                id: leftLine
                width: (250 / 2) - 25
                height: 2
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: settings.color_shape
            }
            Rectangle {
                id: rightLine
                width: (250 / 2) - 25
                height: 2
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: settings.color_shape
            }
        }

       //------------------- start upper 1 --------------------

        Rectangle {
            id: upperLeft1
            visible: settings.show_horizon_ladder
            width: (250 / 4)
            height: 1
            anchors.left: parent.left
            anchors.leftMargin: (250 / 10)
            anchors.bottom: mainHorizon.top
            anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
            color: settings.color_shape
        }
        Rectangle {
            id: upperLeft1Cap
            visible: settings.show_horizon_ladder
            width: 1
            height: 5
            anchors.left: upperLeft1.left
            anchors.top: upperLeft1.bottom
            color: settings.color_shape
        }
        Text {
            id: upperLeft1Text
            visible: settings.show_horizon_ladder
            text: "10"
            color: settings.color_shape
            height: 10
            font.bold: true
            font.pixelSize: 8
            anchors.left: upperLeft1Cap.right
            anchors.top: upperLeft1.bottom
            anchors.leftMargin: 1
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            id: upperRight1
            visible: settings.show_horizon_ladder
            width: (250 / 4)
            height: 1
            anchors.right: parent.right
            anchors.rightMargin: (250 / 10)
            anchors.bottom: mainHorizon.top
            anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
            color: settings.color_shape
        }
        Rectangle {
            id: upperRight1Cap
            visible: settings.show_horizon_ladder
            width: 1
            height: 5
            anchors.right: upperRight1.right
            anchors.top: upperRight1.bottom
            color: settings.color_shape
        }
        Text {
            id: upperRight1Text
            visible: settings.show_horizon_ladder
            text: "10"
            color: settings.color_shape
            height: 10
            font.bold: true
            font.pixelSize: 8
            anchors.right: upperRight1Cap.right
            anchors.top: upperRight1.bottom
            anchors.rightMargin: 2
            verticalAlignment: Text.AlignVCenter
        }
        //------------------- start upper 2 --------------------

         Rectangle {
             id: upperLeft2
             visible: settings.show_horizon_ladder
             width: (250 / 4)
             height: 1
             anchors.left: parent.left
             anchors.leftMargin: (250 / 10)
             anchors.bottom: upperLeft1.top
             anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
             color: settings.color_shape
         }
         Rectangle {
             id: upperLeft2Cap
             visible: settings.show_horizon_ladder
             width: 1
             height: 5
             anchors.left: upperLeft2.left
             anchors.top: upperLeft2.bottom
             color: settings.color_shape
         }
         Text {
             id: upperLeft2Text
             visible: settings.show_horizon_ladder
             text: "20"
             color: settings.color_shape
             height: 10
             font.bold: true
             font.pixelSize: 8
             anchors.left: upperLeft2Cap.right
             anchors.top: upperLeft2.bottom
             anchors.leftMargin: 1
             verticalAlignment: Text.AlignVCenter
         }
         Rectangle {
             id: upperRight2
             visible: settings.show_horizon_ladder
             width: (250 / 4)
             height: 1
             anchors.right: parent.right
             anchors.rightMargin: (250 / 10)
             anchors.bottom: upperRight1.top
             anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
             color: settings.color_shape
         }
         Rectangle {
             id: upperRight2Cap
             visible: settings.show_horizon_ladder
             width: 1
             height: 5
             anchors.right: upperRight2.right
             anchors.top: upperRight2.bottom
             color: settings.color_shape
         }
         Text {
             id: upperRight2Text
             visible: settings.show_horizon_ladder
             text: "20"
             color: settings.color_shape
             height: 10
             font.bold: true
             font.pixelSize: 8
             anchors.right: upperRight2Cap.right
             anchors.top: upperRight2.bottom
             anchors.rightMargin: 2
             verticalAlignment: Text.AlignVCenter
         }

         //------------------- start upper 3 --------------------

          Rectangle {
              id: upperLeft3
              visible: settings.show_horizon_ladder
              width: (250 / 4)
              height: 1
              anchors.left: parent.left
              anchors.leftMargin: (250 / 10)
              anchors.bottom: upperLeft2.top
              anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
              color: settings.color_shape
          }
          Rectangle {
              id: upperLeft3Cap
              visible: settings.show_horizon_ladder
              width: 1
              height: 5
              anchors.left: upperLeft3.left
              anchors.top: upperLeft3.bottom
              color: settings.color_shape
          }
          Text {
              id: upperLeft3Text
              visible: settings.show_horizon_ladder
              text: "30"
              color: settings.color_shape
              height: 10
              font.bold: true
              font.pixelSize: 8
              anchors.left: upperLeft3Cap.right
              anchors.top: upperLeft3.bottom
              anchors.leftMargin: 1
              verticalAlignment: Text.AlignVCenter
          }
          Rectangle {
              id: upperRight3
              visible: settings.show_horizon_ladder
              width: (250 / 4)
              height: 1
              anchors.right: parent.right
              anchors.rightMargin: (250 / 10)
              anchors.bottom: upperRight2.top
              anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
              color: settings.color_shape
          }
          Rectangle {
              id: upperRight3Cap
              visible: settings.show_horizon_ladder
              width: 1
              height: 5
              anchors.right: upperRight3.right
              anchors.top: upperRight3.bottom
              color: settings.color_shape
          }
          Text {
              id: upperRight3Text
              visible: settings.show_horizon_ladder
              text: "30"
              color: settings.color_shape
              height: 10
              font.bold: true
              font.pixelSize: 8
              anchors.right: upperRight3Cap.right
              anchors.top: upperRight3.bottom
              anchors.rightMargin: 2
              verticalAlignment: Text.AlignVCenter
          }

          //------------------- start upper 4 --------------------

           Rectangle {
               id: upperLeft4
               visible: settings.show_horizon_ladder
               width: (250 / 4)
               height: 1
               anchors.left: parent.left
               anchors.leftMargin: (250 / 10)
               anchors.bottom: upperLeft3.top
               anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
               color: settings.color_shape
           }
           Rectangle {
               id: upperLeft4Cap
               visible: settings.show_horizon_ladder
               width: 1
               height: 5
               anchors.left: upperLeft4.left
               anchors.top: upperLeft4.bottom
               color: settings.color_shape
           }
           Text {
               id: upperLeft4Text
               visible: settings.show_horizon_ladder
               text: "40"
               color: settings.color_shape
               height: 10
               font.bold: true
               font.pixelSize: 8
               anchors.left: upperLeft4Cap.right
               anchors.top: upperLeft4.bottom
               anchors.leftMargin: 1
               verticalAlignment: Text.AlignVCenter
           }
           Rectangle {
               id: upperRight4
               visible: settings.show_horizon_ladder
               width: (250 / 4)
               height: 1
               anchors.right: parent.right
               anchors.rightMargin: (250 / 10)
               anchors.bottom: upperRight3.top
               anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
               color: settings.color_shape
           }
           Rectangle {
               id: upperRight4Cap
               visible: settings.show_horizon_ladder
               width: 1
               height: 5
               anchors.right: upperRight4.right
               anchors.top: upperRight4.bottom
               color: settings.color_shape
           }
           Text {
               id: upperRight4Text
               visible: settings.show_horizon_ladder
               text: "40"
               color: settings.color_shape
               height: 10
               font.bold: true
               font.pixelSize: 8
               anchors.right: upperRight4Cap.right
               anchors.top: upperRight4.bottom
               anchors.rightMargin: 2
               verticalAlignment: Text.AlignVCenter
           }

           //------------------- start upper 5 --------------------

            Rectangle {
                id: upperLeft5
                visible: settings.show_horizon_ladder
                width: (250 / 4)
                height: 1
                anchors.left: parent.left
                anchors.leftMargin: (250 / 10)
                anchors.bottom: upperLeft4.top
                anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
                color: settings.color_shape
            }
            Rectangle {
                id: upperLeft5Cap
                visible: settings.show_horizon_ladder
                width: 1
                height: 5
                anchors.left: upperLeft5.left
                anchors.top: upperLeft5.bottom
                color: settings.color_shape
            }
            Text {
                id: upperLeft5Text
                visible: settings.show_horizon_ladder
                text: "50"
                color: settings.color_shape
                height: 10
                font.bold: true
                font.pixelSize: 8
                anchors.left: upperLeft5Cap.right
                anchors.top: upperLeft5.bottom
                anchors.leftMargin: 1
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                id: upperRight5
                visible: settings.show_horizon_ladder
                width: (250 / 4)
                height: 1
                anchors.right: parent.right
                anchors.rightMargin: (250 / 10)
                anchors.bottom: upperRight4.top
                anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
                color: settings.color_shape
            }
            Rectangle {
                id: upperRight5Cap
                visible: settings.show_horizon_ladder
                width: 1
                height: 5
                anchors.right: upperRight5.right
                anchors.top: upperRight5.bottom
                color: settings.color_shape
            }
            Text {
                id: upperRight5Text
                visible: settings.show_horizon_ladder
                text: "50"
                color: settings.color_shape
                height: 10
                font.bold: true
                font.pixelSize: 8
                anchors.right: upperRight5Cap.right
                anchors.top: upperRight5.bottom
                anchors.rightMargin: 2
                verticalAlignment: Text.AlignVCenter
            }

            //------------------- start upper 6 --------------------

             Rectangle {
                 id: upperLeft6
                 visible: settings.show_horizon_ladder
                 width: (250 / 4)
                 height: 1
                 anchors.left: parent.left
                 anchors.leftMargin: (250 / 10)
                 anchors.bottom: upperLeft5.top
                 anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
                 color: settings.color_shape
             }
             Rectangle {
                 id: upperLeft6Cap
                 visible: settings.show_horizon_ladder
                 width: 1
                 height: 5
                 anchors.left: upperLeft6.left
                 anchors.top: upperLeft6.bottom
                 color: settings.color_shape
             }
             Text {
                 id: upperLeft6Text
                 visible: settings.show_horizon_ladder
                 text: "60"
                 color: settings.color_shape
                 height: 10
                 font.bold: true
                 font.pixelSize: 8
                 anchors.left: upperLeft6Cap.right
                 anchors.top: upperLeft6.bottom
                 anchors.leftMargin: 1
                 verticalAlignment: Text.AlignVCenter
             }
             Rectangle {
                 id: upperRight6
                 visible: settings.show_horizon_ladder
                 width: (250 / 4)
                 height: 1
                 anchors.right: parent.right
                 anchors.rightMargin: (250 / 10)
                 anchors.bottom: upperRight5.top
                 anchors.bottomMargin: 10 * settings.horizon_ladder_spacing
                 color: settings.color_shape
             }
             Rectangle {
                 id: upperRight6Cap
                 visible: settings.show_horizon_ladder
                 width: 1
                 height: 5
                 anchors.right: upperRight6.right
                 anchors.top: upperRight6.bottom
                 color: settings.color_shape
             }
             Text {
                 id: upperRight6Text
                 visible: settings.show_horizon_ladder
                 text: "60"
                 color: settings.color_shape
                 height: 10
                 font.bold: true
                 font.pixelSize: 8
                 anchors.right: upperRight6Cap.right
                 anchors.top: upperRight6.bottom
                 anchors.rightMargin: 2
                 verticalAlignment: Text.AlignVCenter
             }

      //--------------------start lower pitch lines -----------------------------------
             //------------------- start lower 1 --------------------

              Rectangle {
                  id: lowerLeft1
                  visible: settings.show_horizon_ladder
                  width: (250 / 24)
                  height: 1
                  anchors.left: parent.left
                  anchors.leftMargin: (250 / 10)
                  anchors.top: mainHorizon.bottom
                  anchors.topMargin: 10 * settings.horizon_ladder_spacing
                  color: settings.color_shape
              }
              Rectangle {
                  id: lowerLeft1middle
                  visible: settings.show_horizon_ladder
                  width: (250 / 24)
                  height: 1
                  anchors.left: lowerLeft1.right
                  anchors.leftMargin: (250 / 24)
                  anchors.top: mainHorizon.bottom
                  anchors.topMargin: 10 * settings.horizon_ladder_spacing
                  color: settings.color_shape
              }
              Rectangle {
                  id: lowerLeft1inner
                  visible: settings.show_horizon_ladder
                  width: (250 / 24)
                  height: 1
                  anchors.left: lowerLeft1middle.right
                  anchors.leftMargin: (250 / 24)
                  anchors.top: mainHorizon.bottom
                  anchors.topMargin: 10 * settings.horizon_ladder_spacing
                  color: settings.color_shape
              }
              Rectangle {
                  id: lowerLeft1Cap
                  visible: settings.show_horizon_ladder
                  width: 1
                  height: 5
                  anchors.left: lowerLeft1.left
                  anchors.bottom: lowerLeft1.top
                  color: settings.color_shape
              }
              Text {
                  id: lowerLeft1Text
                  visible: settings.show_horizon_ladder
                  text: "-10"
                  color: settings.color_shape
                  height: 10
                  font.bold: true
                  font.pixelSize: 8
                  anchors.left: lowerLeft1Cap.right
                  anchors.bottom: lowerLeft1.top
                  anchors.leftMargin: 1
                  verticalAlignment: Text.AlignVCenter
              }
              Rectangle {
                  id: lowerRight1
                  visible: settings.show_horizon_ladder
                  width: (250 / 24)
                  height: 1
                  anchors.right: parent.right
                  anchors.rightMargin: (250 / 10)
                  anchors.top: mainHorizon.bottom
                  anchors.topMargin: 10 * settings.horizon_ladder_spacing
                  color: settings.color_shape
              }
              Rectangle {
                  id: lowerRight1middle
                  visible: settings.show_horizon_ladder
                  width: (250 / 24)
                  height: 1
                  anchors.right: lowerRight1.left
                  anchors.rightMargin: (250 / 24)
                  anchors.top: mainHorizon.bottom
                  anchors.topMargin: 10 * settings.horizon_ladder_spacing
                  color: settings.color_shape
              }
              Rectangle {
                  id: lowerRight1inner
                  visible: settings.show_horizon_ladder
                  width: (250 / 24)
                  height: 1
                  anchors.right: lowerRight1middle.left
                  anchors.rightMargin: (250 / 24)
                  anchors.top: mainHorizon.bottom
                  anchors.topMargin: 10 * settings.horizon_ladder_spacing
                  color: settings.color_shape
              }
              Rectangle {
                  id: lowerRight1Cap
                  visible: settings.show_horizon_ladder
                  width: 1
                  height: 5
                  anchors.right: lowerRight1.right
                  anchors.bottom: lowerRight1.bottom
                  color: settings.color_shape
              }
              Text {
                  id: lowerRight1Text
                  visible: settings.show_horizon_ladder
                  text: "-10"
                  color: settings.color_shape
                  height: 10
                  font.bold: true
                  font.pixelSize: 8
                  anchors.right: lowerRight1Cap.right
                  anchors.bottom: lowerRight1.top
                  anchors.rightMargin: 2
                  verticalAlignment: Text.AlignVCenter
              }

              //------------------- start lower 2 --------------------

               Rectangle {
                   id: lowerLeft2
                   visible: settings.show_horizon_ladder
                   width: (250 / 24)
                   height: 1
                   anchors.left: parent.left
                   anchors.leftMargin: (250 / 10)
                   anchors.top: lowerLeft1.bottom
                   anchors.topMargin: 10 * settings.horizon_ladder_spacing
                   color: settings.color_shape
               }
               Rectangle {
                   id: lowerLeft2middle
                   visible: settings.show_horizon_ladder
                   width: (250 / 24)
                   height: 1
                   anchors.left: lowerLeft2.right
                   anchors.leftMargin: (250 / 24)
                   anchors.top: lowerLeft1.bottom
                   anchors.topMargin: 10 * settings.horizon_ladder_spacing
                   color: settings.color_shape
               }
               Rectangle {
                   id: lowerLeft2inner
                   visible: settings.show_horizon_ladder
                   width: (250 / 24)
                   height: 1
                   anchors.left: lowerLeft2middle.right
                   anchors.leftMargin: (250 / 24)
                   anchors.top: lowerLeft1.bottom
                   anchors.topMargin: 10 * settings.horizon_ladder_spacing
                   color: settings.color_shape
               }
               Rectangle {
                   id: lowerLeft2Cap
                   visible: settings.show_horizon_ladder
                   width: 1
                   height: 5
                   anchors.left: lowerLeft2.left
                   anchors.bottom: lowerLeft2.top
                   color: settings.color_shape
               }
               Text {
                   id: lowerLeft2Text
                   visible: settings.show_horizon_ladder
                   text: "-20"
                   color: settings.color_shape
                   height: 10
                   font.bold: true
                   font.pixelSize: 8
                   anchors.left: lowerLeft2Cap.right
                   anchors.bottom: lowerLeft2.top
                   anchors.leftMargin: 1
                   verticalAlignment: Text.AlignVCenter
               }
               Rectangle {
                   id: lowerRight2
                   visible: settings.show_horizon_ladder
                   width: (250 / 24)
                   height: 1
                   anchors.right: parent.right
                   anchors.rightMargin: (250 / 10)
                   anchors.top: lowerLeft1.bottom
                   anchors.topMargin: 10 * settings.horizon_ladder_spacing
                   color: settings.color_shape
               }
               Rectangle {
                   id: lowerRight2middle
                   visible: settings.show_horizon_ladder
                   width: (250 / 24)
                   height: 1
                   anchors.right: lowerRight2.left
                   anchors.rightMargin: (250 / 24)
                   anchors.top: lowerRight1.bottom
                   anchors.topMargin: 10 * settings.horizon_ladder_spacing
                   color: settings.color_shape
               }
               Rectangle {
                   id: lowerRight2inner
                   visible: settings.show_horizon_ladder
                   width: (250 / 24)
                   height: 1
                   anchors.right: lowerRight2middle.left
                   anchors.rightMargin: (250 / 24)
                   anchors.top: lowerRight1.bottom
                   anchors.topMargin: 10 * settings.horizon_ladder_spacing
                   color: settings.color_shape
               }
               Rectangle {
                   id: lowerRight2Cap
                   visible: settings.show_horizon_ladder
                   width: 1
                   height: 5
                   anchors.right: lowerRight2.right
                   anchors.bottom: lowerRight2.bottom
                   color: settings.color_shape
               }
               Text {
                   id: lowerRight2Text
                   visible: settings.show_horizon_ladder
                   text: "-20"
                   color: settings.color_shape
                   height: 10
                   font.bold: true
                   font.pixelSize: 8
                   anchors.right: lowerRight2Cap.right
                   anchors.bottom: lowerRight2.top
                   anchors.rightMargin: 2
                   verticalAlignment: Text.AlignVCenter
               }

               //------------------- start lower 3 --------------------

                Rectangle {
                    id: lowerLeft3
                    visible: settings.show_horizon_ladder
                    width: (250 / 24)
                    height: 1
                    anchors.left: parent.left
                    anchors.leftMargin: (250 / 10)
                    anchors.top: lowerLeft2.bottom
                    anchors.topMargin: 10 * settings.horizon_ladder_spacing
                    color: settings.color_shape
                }
                Rectangle {
                    id: lowerLeft3middle
                    visible: settings.show_horizon_ladder
                    width: (250 / 24)
                    height: 1
                    anchors.left: lowerLeft3.right
                    anchors.leftMargin: (250 / 24)
                    anchors.top: lowerLeft2.bottom
                    anchors.topMargin: 10 * settings.horizon_ladder_spacing
                    color: settings.color_shape
                }
                Rectangle {
                    id: lowerLeft3inner
                    visible: settings.show_horizon_ladder
                    width: (250 / 24)
                    height: 1
                    anchors.left: lowerLeft3middle.right
                    anchors.leftMargin: (250 / 24)
                    anchors.top: lowerLeft2.bottom
                    anchors.topMargin: 10 * settings.horizon_ladder_spacing
                    color: settings.color_shape
                }
                Rectangle {
                    id: lowerLeft3Cap
                    visible: settings.show_horizon_ladder
                    width: 1
                    height: 5
                    anchors.left: lowerLeft3.left
                    anchors.bottom: lowerLeft3.top
                    color: settings.color_shape
                }
                Text {
                    id: lowerLeft3Text
                    visible: settings.show_horizon_ladder
                    text: "-30"
                    color: settings.color_shape
                    height: 10
                    font.bold: true
                    font.pixelSize: 8
                    anchors.left: lowerLeft3Cap.right
                    anchors.bottom: lowerLeft3.top
                    anchors.leftMargin: 1
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: lowerRight3
                    visible: settings.show_horizon_ladder
                    width: (250 / 24)
                    height: 1
                    anchors.right: parent.right
                    anchors.rightMargin: (250 / 10)
                    anchors.top: lowerLeft2.bottom
                    anchors.topMargin: 10 * settings.horizon_ladder_spacing
                    color: settings.color_shape
                }
                Rectangle {
                    id: lowerRight3middle
                    visible: settings.show_horizon_ladder
                    width: (250 / 24)
                    height: 1
                    anchors.right: lowerRight3.left
                    anchors.rightMargin: (250 / 24)
                    anchors.top: lowerRight2.bottom
                    anchors.topMargin: 10 * settings.horizon_ladder_spacing
                    color: settings.color_shape
                }
                Rectangle {
                    id: lowerRight3inner
                    visible: settings.show_horizon_ladder
                    width: (250 / 24)
                    height: 1
                    anchors.right: lowerRight3middle.left
                    anchors.rightMargin: (250 / 24)
                    anchors.top: lowerRight2.bottom
                    anchors.topMargin: 10 * settings.horizon_ladder_spacing
                    color: settings.color_shape
                }
                Rectangle {
                    id: lowerRight3Cap
                    visible: settings.show_horizon_ladder
                    width: 1
                    height: 5
                    anchors.right: lowerRight3.right
                    anchors.bottom: lowerRight3.bottom
                    color: settings.color_shape
                }
                Text {
                    id: lowerRight3Text
                    visible: settings.show_horizon_ladder
                    text: "-30"
                    color: settings.color_shape
                    height: 10
                    font.bold: true
                    font.pixelSize: 8
                    anchors.right: lowerRight3Cap.right
                    anchors.bottom: lowerRight3.top
                    anchors.rightMargin: 2
                    verticalAlignment: Text.AlignVCenter
                }

                //------------------- start lower 4 --------------------

                 Rectangle {
                     id: lowerLeft4
                     visible: settings.show_horizon_ladder
                     width: (250 / 24)
                     height: 1
                     anchors.left: parent.left
                     anchors.leftMargin: (250 / 10)
                     anchors.top: lowerLeft3.bottom
                     anchors.topMargin: 10 * settings.horizon_ladder_spacing
                     color: settings.color_shape
                 }
                 Rectangle {
                     id: lowerLeft4middle
                     visible: settings.show_horizon_ladder
                     width: (250 / 24)
                     height: 1
                     anchors.left: lowerLeft4.right
                     anchors.leftMargin: (250 / 24)
                     anchors.top: lowerLeft3.bottom
                     anchors.topMargin: 10 * settings.horizon_ladder_spacing
                     color: settings.color_shape
                 }
                 Rectangle {
                     id: lowerLeft4inner
                     visible: settings.show_horizon_ladder
                     width: (250 / 24)
                     height: 1
                     anchors.left: lowerLeft4middle.right
                     anchors.leftMargin: (250 / 24)
                     anchors.top: lowerLeft3.bottom
                     anchors.topMargin: 10 * settings.horizon_ladder_spacing
                     color: settings.color_shape
                 }
                 Rectangle {
                     id: lowerLeft4Cap
                     visible: settings.show_horizon_ladder
                     width: 1
                     height: 5
                     anchors.left: lowerLeft4.left
                     anchors.bottom: lowerLeft4.top
                     color: settings.color_shape
                 }
                 Text {
                     id: lowerLeft4Text
                     visible: settings.show_horizon_ladder
                     text: "-40"
                     color: settings.color_shape
                     height: 10
                     font.bold: true
                     font.pixelSize: 8
                     anchors.left: lowerLeft4Cap.right
                     anchors.bottom: lowerLeft4.top
                     anchors.leftMargin: 1
                     verticalAlignment: Text.AlignVCenter
                 }
                 Rectangle {
                     id: lowerRight4
                     visible: settings.show_horizon_ladder
                     width: (250 / 24)
                     height: 1
                     anchors.right: parent.right
                     anchors.rightMargin: (250 / 10)
                     anchors.top: lowerLeft3.bottom
                     anchors.topMargin: 10 * settings.horizon_ladder_spacing
                     color: settings.color_shape
                 }
                 Rectangle {
                     id: lowerRight4middle
                     visible: settings.show_horizon_ladder
                     width: (250 / 24)
                     height: 1
                     anchors.right: lowerRight4.left
                     anchors.rightMargin: (250 / 24)
                     anchors.top: lowerRight3.bottom
                     anchors.topMargin: 10 * settings.horizon_ladder_spacing
                     color: settings.color_shape
                 }
                 Rectangle {
                     id: lowerRight4inner
                     visible: settings.show_horizon_ladder
                     width: (250 / 24)
                     height: 1
                     anchors.right: lowerRight4middle.left
                     anchors.rightMargin: (250 / 24)
                     anchors.top: lowerRight3.bottom
                     anchors.topMargin: 10 * settings.horizon_ladder_spacing
                     color: settings.color_shape
                 }
                 Rectangle {
                     id: lowerRight4Cap
                     visible: settings.show_horizon_ladder
                     width: 1
                     height: 5
                     anchors.right: lowerRight4.right
                     anchors.bottom: lowerRight4.bottom
                     color: settings.color_shape
                 }
                 Text {
                     id: lowerRight4Text
                     visible: settings.show_horizon_ladder
                     text: "-40"
                     color: settings.color_shape
                     height: 10
                     font.bold: true
                     font.pixelSize: 8
                     anchors.right: lowerRight4Cap.right
                     anchors.bottom: lowerRight4.top
                     anchors.rightMargin: 2
                     verticalAlignment: Text.AlignVCenter
                 }

                 //------------------- start lower 5 --------------------

                  Rectangle {
                      id: lowerLeft5
                      visible: settings.show_horizon_ladder
                      width: (250 / 24)
                      height: 1
                      anchors.left: parent.left
                      anchors.leftMargin: (250 / 10)
                      anchors.top: lowerLeft4.bottom
                      anchors.topMargin: 10 * settings.horizon_ladder_spacing
                      color: settings.color_shape
                  }
                  Rectangle {
                      id: lowerLeft5middle
                      visible: settings.show_horizon_ladder
                      width: (250 / 24)
                      height: 1
                      anchors.left: lowerLeft5.right
                      anchors.leftMargin: (250 / 24)
                      anchors.top: lowerLeft4.bottom
                      anchors.topMargin: 10 * settings.horizon_ladder_spacing
                      color: settings.color_shape
                  }
                  Rectangle {
                      id: lowerLeft5inner
                      visible: settings.show_horizon_ladder
                      width: (250 / 24)
                      height: 1
                      anchors.left: lowerLeft5middle.right
                      anchors.leftMargin: (250 / 24)
                      anchors.top: lowerLeft4.bottom
                      anchors.topMargin: 10 * settings.horizon_ladder_spacing
                      color: settings.color_shape
                  }
                  Rectangle {
                      id: lowerLeft5Cap
                      visible: settings.show_horizon_ladder
                      width: 1
                      height: 5
                      anchors.left: lowerLeft5.left
                      anchors.bottom: lowerLeft5.top
                      color: settings.color_shape
                  }
                  Text {
                      id: lowerLeft5Text
                      visible: settings.show_horizon_ladder
                      text: "-50"
                      color: settings.color_shape
                      height: 10
                      font.bold: true
                      font.pixelSize: 8
                      anchors.left: lowerLeft5Cap.right
                      anchors.bottom: lowerLeft5.top
                      anchors.leftMargin: 1
                      verticalAlignment: Text.AlignVCenter
                  }
                  Rectangle {
                      id: lowerRight5
                      visible: settings.show_horizon_ladder
                      width: (250 / 24)
                      height: 1
                      anchors.right: parent.right
                      anchors.rightMargin: (250 / 10)
                      anchors.top: lowerLeft4.bottom
                      anchors.topMargin: 10 * settings.horizon_ladder_spacing
                      color: settings.color_shape
                  }
                  Rectangle {
                      id: lowerRight5middle
                      visible: settings.show_horizon_ladder
                      width: (250 / 24)
                      height: 1
                      anchors.right: lowerRight5.left
                      anchors.rightMargin: (250 / 24)
                      anchors.top: lowerRight4.bottom
                      anchors.topMargin: 10 * settings.horizon_ladder_spacing
                      color: settings.color_shape
                  }
                  Rectangle {
                      id: lowerRight5inner
                      visible: settings.show_horizon_ladder
                      width: (250 / 24)
                      height: 1
                      anchors.right: lowerRight5middle.left
                      anchors.rightMargin: (250 / 24)
                      anchors.top: lowerRight4.bottom
                      anchors.topMargin: 10 * settings.horizon_ladder_spacing
                      color: settings.color_shape
                  }
                  Rectangle {
                      id: lowerRight5Cap
                      visible: settings.show_horizon_ladder
                      width: 1
                      height: 5
                      anchors.right: lowerRight5.right
                      anchors.bottom: lowerRight5.bottom
                      color: settings.color_shape
                  }
                  Text {
                      id: lowerRight5Text
                      visible: settings.show_horizon_ladder
                      text: "-50"
                      color: settings.color_shape
                      height: 10
                      font.bold: true
                      font.pixelSize: 8
                      anchors.right: lowerRight5Cap.right
                      anchors.bottom: lowerRight5.top
                      anchors.rightMargin: 2
                      verticalAlignment: Text.AlignVCenter
                  }

                  //------------------- start lower 6 --------------------

                   Rectangle {
                       id: lowerLeft6
                       visible: settings.show_horizon_ladder
                       width: (250 / 24)
                       height: 1
                       anchors.left: parent.left
                       anchors.leftMargin: (250 / 10)
                       anchors.top: lowerLeft5.bottom
                       anchors.topMargin: 10 * settings.horizon_ladder_spacing
                       color: settings.color_shape
                   }
                   Rectangle {
                       id: lowerLeft6middle
                       visible: settings.show_horizon_ladder
                       width: (250 / 24)
                       height: 1
                       anchors.left: lowerLeft6.right
                       anchors.leftMargin: (250 / 24)
                       anchors.top: lowerLeft5.bottom
                       anchors.topMargin: 10 * settings.horizon_ladder_spacing
                       color: settings.color_shape
                   }
                   Rectangle {
                       id: lowerLeft6inner
                       visible: settings.show_horizon_ladder
                       width: (250 / 24)
                       height: 1
                       anchors.left: lowerLeft6middle.right
                       anchors.leftMargin: (250 / 24)
                       anchors.top: lowerLeft5.bottom
                       anchors.topMargin: 10 * settings.horizon_ladder_spacing
                       color: settings.color_shape
                   }
                   Rectangle {
                       id: lowerLeft6Cap
                       visible: settings.show_horizon_ladder
                       width: 1
                       height: 5
                       anchors.left: lowerLeft6.left
                       anchors.bottom: lowerLeft6.top
                       color: settings.color_shape
                   }
                   Text {
                       id: lowerLeft6Text
                       visible: settings.show_horizon_ladder
                       text: "-60"
                       color: settings.color_shape
                       height: 10
                       font.bold: true
                       font.pixelSize: 8
                       anchors.left: lowerLeft6Cap.right
                       anchors.bottom: lowerLeft6.top
                       anchors.leftMargin: 1
                       verticalAlignment: Text.AlignVCenter
                   }
                   Rectangle {
                       id: lowerRight6
                       visible: settings.show_horizon_ladder
                       width: (250 / 24)
                       height: 1
                       anchors.right: parent.right
                       anchors.rightMargin: (250 / 10)
                       anchors.top: lowerLeft5.bottom
                       anchors.topMargin: 10 * settings.horizon_ladder_spacing
                       color: settings.color_shape
                   }
                   Rectangle {
                       id: lowerRight6middle
                       visible: settings.show_horizon_ladder
                       width: (250 / 24)
                       height: 1
                       anchors.right: lowerRight6.left
                       anchors.rightMargin: (250 / 24)
                       anchors.top: lowerRight5.bottom
                       anchors.topMargin: 10 * settings.horizon_ladder_spacing
                       color: settings.color_shape
                   }
                   Rectangle {
                       id: lowerRight6inner
                       visible: settings.show_horizon_ladder
                       width: (250 / 24)
                       height: 1
                       anchors.right: lowerRight6middle.left
                       anchors.rightMargin: (250 / 24)
                       anchors.top: lowerRight5.bottom
                       anchors.topMargin: 10 * settings.horizon_ladder_spacing
                       color: settings.color_shape
                   }
                   Rectangle {
                       id: lowerRight6Cap
                       visible: settings.show_horizon_ladder
                       width: 1
                       height: 5
                       anchors.right: lowerRight6.right
                       anchors.bottom: lowerRight6.bottom
                       color: settings.color_shape
                   }
                   Text {
                       id: lowerRight6Text
                       visible: settings.show_horizon_ladder
                       text: "-60"
                       color: settings.color_shape
                       height: 10
                       font.bold: true
                       font.pixelSize: 8
                       anchors.right: lowerRight6Cap.right
                       anchors.bottom: lowerRight6.top
                       anchors.rightMargin: 2
                       verticalAlignment: Text.AlignVCenter
                   }
    }
}

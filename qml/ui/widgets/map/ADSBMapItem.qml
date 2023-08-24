import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.0

import QtLocation 5.15
import QtPositioning 5.15
import OpenHD 1.0


// Copied over luke's map adsb stuff into here.
// Needs a big refactor before it is functional (again)
// Currently out commented, to track down map issues
Item {

    // ? ADSB stuff ?
    MapRectangle {
        id: adsbSquare
        topLeft : AdsbVehicleManager.apiMapCenter.atDistanceAndAzimuth(settings.adsb_distance_limit, 315, 0.0)
        bottomRight: AdsbVehicleManager.apiMapCenter.atDistanceAndAzimuth(settings.adsb_distance_limit, 135, 0.0)
        //enabled: false
        visible: settings.adsb_api_openskynetwork
        color: "white"
        border.color: "red"
        border.width: 5
        smooth: true
        opacity: .3
    }
    // ? ADSB stuff ?
    MapItemView {
        id: markerMapView
    //TODO ADSB needs refactor
        model: AdsbVehicleManager.adsbVehicles
        delegate: markerComponentDelegate
        //visible: false

        Component {
            id: markerComponentDelegate

            MapItemGroup {
                id: delegateGroup

                MapQuickItem {
                    id: marker

                    anchorPoint.x: 0
                    anchorPoint.y: 0
                    width: 260
                    height: 260


                    sourceItem:

                        DrawingCanvas {
                        id: icon
                        anchors.centerIn: parent

                        width: 260
                        height: 260

                        color: settings.color_shape
                        glow: settings.color_glow

                        name: object.callsign

                        drone_heading: OpenHD.hdg; //need this to adjust orientation

                        drone_alt: OpenHD.alt_msl;

                        heading: object.heading;

                        speed: object.velocity

                        alt: object.altitude

//                          {
/*                          check if traffic is a threat.. this should not be done here. Left as REF
                                if (object.altitude - OpenHD.alt_msl < 300 && model.distance < 2){
                                    //console.log("TRAFFIC WARNING");

                                    //image.source="/airplanemarkerwarn.png";
                                    background.border.color = "red";
                                    background.border.width = 5;
                                    background.opacity = 0.5;
                                } else if (object.altitude - OpenHD.alt_msl < 500 && model.distance < 5){
                                    //console.log("TRAFFIC ALERT");

                                    //image.source="/airplanemarkeralert.png";
                                    background.border.color = "yellow";
                                    background.border.width = 5;
                                    background.opacity = 0.5;
                                }
*/

/*                          *discovered issues when the object is referenced multiple times
                            *last attempt at putting altitude into a var still resulted in "nulls"

                            var _adsb_alt;

                            _adsb_alt=object.altitude;

                            if ( _adsb_alt> 9999) {
                                //console.log("qml: model alt or vertical undefined")
                               return "---";
                            } else {
                                if(object.verticalVel > .2){ //climbing
                                    if (settings.enable_imperial === false){
                                        return Math.floor(_adsb_alt - OpenHD.alt_msl) + "m " + "\ue696"
                                    }
                                    else{
                                        return Math.floor((_adsb_alt - OpenHD.alt_msl) * 3.28084) + "Ft " + "\ue696"
                                    }
                                }
                                else if (object.verticalVel < -.2){//descending
                                    if (settings.enable_imperial === false){
                                        return Math.floor(_adsb_alt - OpenHD.alt_msl) + "m " + "\ue697"
                                    }
                                    else{
                                        return Math.floor((_adsb_alt - OpenHD.alt_msl) * 3.28084) + "Ft " + "\ue697"
                                    }
                                }
                                else {
                                    if (settings.enable_imperial === false){//level
                                        return Math.floor(_adsb_alt - OpenHD.alt_msl) + "m " + "\u2501"
                                    }
                                    else{
                                        return Math.floor((_adsb_alt - OpenHD.alt_msl) * 3.28084) + "Ft " + "\u2501"
                                    }
                                }
                            }
                        }
  */
                    }
                    //position everything
                    coordinate: object.coordinate;

                }
                //Component.onCompleted: map.addMapItemGroup(this);
            }
        }
    }

}

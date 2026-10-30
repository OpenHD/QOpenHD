import QtQuick 2.12
Item {
 property real initialLatitude:0;property real initialLongitude:0
 property string tileCacheDirectory:"";property string tileHost:"";property bool usingMapbox:false
 property bool radiusMode:true;property bool drawing:false;property bool selectionValid:false
 property real south:50;property real north:51;property real west:7;property real east:8
 function selectCenterRadius(){selectionValid=true}
 function fitRegion(region){south=region.south;north=region.north;west=region.west;east=region.east;selectionValid=true}
 Rectangle {anchors.fill:parent;color:"#214251"}
}

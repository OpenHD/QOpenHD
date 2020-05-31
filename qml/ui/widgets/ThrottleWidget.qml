import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import OpenHD 1.0

ThrottleWidgetForm {

    function map(input, input_start, input_end, output_start, output_end) {
        var input_range = input_end - input_start;
        var output_range = output_end - output_start;

        return (input - input_start)*output_range / input_range + output_start;
    }

    Connections {
        target: OpenHD

        function onThrottleChanged(throttle) {
            gaugeAngle = map(throttle, 0, 100, 0, 180);
        }
    }
}

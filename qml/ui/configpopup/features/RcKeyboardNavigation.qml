/******************************************************************************
 * OpenHD
 *
 * Licensed under the GNU General Public License (GPL) Version 3.
 *
 * This software is provided "as-is," without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose, and non-infringement. For details, see the
 * full license in the LICENSE file provided with this source code.
 *
 * Non-Military Use Only:
 * This software and its associated components are explicitly intended for
 * civilian and non-military purposes. Use in any military or defense
 * applications is strictly prohibited unless explicitly and individually
 * licensed otherwise by the OpenHD Team.
 *
 * Contributors:
 * A full list of contributors can be found at the OpenHD GitHub repository:
 * https://github.com/OpenHD
 *
 * © OpenHD, All Rights Reserved.
 ******************************************************************************/

import QtQuick 2.12
import "RcRanges.js" as Ranges

Item {
    id: root
    property var channelModel
    property string mapping: "{}"
    property bool suspended: false
    readonly property var profiles: Ranges.keyboardProfiles(mapping)
    property var previousAreas: ({})
    signal keyPressed(int key)

    onSuspendedChanged: previousAreas = ({})
    onProfilesChanged: previousAreas = ({})
    onChannelModelChanged: previousAreas = ({})

    Connections {
        target: root.channelModel
        enabled: !root.suspended && Object.keys(root.profiles).length > 0
        function onChannelsUpdated() { root.sample() }
        function onIs_aliveChanged() {
            if (!root.channelModel.is_alive) root.previousAreas = ({})
        }
    }

    function sample() {
        const channels = channelModel.channelValues()
        const next = {}
        const pressed = []
        Object.keys(profiles).forEach(function(channel) {
            const pwm = channels[channel - 1]
            if (!(pwm >= 900 && pwm <= 2100)) return
            const ranges = profiles[channel]
            const before = previousAreas[channel]
            var area = ranges.findIndex(function(range) { return pwm <= range.upper })
            if (before !== undefined && ranges[before].value !== 0) {
                // Require a short move past a keyed range before re-arming it.
                const low = before === 0 ? 900 : ranges[before - 1].upper + 1
                if (pwm >= low - 6 && pwm <= ranges[before].upper + 6) area = before
            }
            next[channel] = area
            const key = ranges[area].value
            if (before !== undefined && key !== 0 && key !== ranges[before].value && pressed.indexOf(key) < 0)
                pressed.push(key)
        })
        previousAreas = next
        pressed.forEach(function(key) { root.keyPressed(key) })
    }
}

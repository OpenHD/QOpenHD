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

.pragma library

function parse(text) {
    if (!text || text.length > 128) return []
    var entries = text.split(","), ranges = [], previous = 899
    if (entries.length > 5) return []
    for (var i = 0; i < entries.length; ++i) {
        if (!/^\d+:\d+$/.test(entries[i])) return []
        var parts = entries[i].split(":"), upper = Number(parts[0]), value = Number(parts[1])
        if (upper <= previous || upper > 2100) return []
        ranges.push({upper: upper, value: value}); previous = upper
    }
    return previous === 2100 ? ranges : []
}
function encode(ranges) {
    return ranges.map(function(range) { return range.upper + ":" + range.value }).join(",")
}
function valid(ranges, values) {
    var parsed = parse(encode(ranges))
    return parsed.length > 0 && parsed.every(function(range) { return values.indexOf(range.value) >= 0 })
}
function copy(ranges) { return ranges.map(function(range) { return {upper: range.upper, value: range.value} }) }
function setValue(ranges, index, value) {
    var next = copy(ranges); next[index].value = value; return next
}
function setBoundary(ranges, index, upper) {
    var next = copy(ranges)
    if (index < 0 || index >= next.length-1) return next
    var low = index === 0 ? 900 : next[index-1].upper+1
    next[index].upper = Math.max(low, Math.min(next[index+1].upper-1, Math.round(upper)))
    return next
}
function split(ranges, index, value) {
    var next = copy(ranges)
    if (next.length >= 5 || index < 0 || index >= next.length) return next
    var low = index === 0 ? 900 : next[index-1].upper+1, high = next[index].upper
    if (high <= low) return next
    next.splice(index, 1, {upper: Math.floor((low+high)/2), value: next[index].value}, {upper: high, value: value})
    return next
}
function remove(ranges, index) {
    var next = copy(ranges)
    if (next.length <= 1 || index < 0 || index >= next.length) return next
    if (index === next.length-1) next[index-1].upper = 2100
    next.splice(index, 1)
    return next
}

function keyboardOptions() {
    return [
        { value: 0, text: qsTr("No key") },
        { value: Qt.Key_Right, text: qsTr("Right") },
        { value: Qt.Key_Left, text: qsTr("Left") },
        { value: Qt.Key_Up, text: qsTr("Up") },
        { value: Qt.Key_Down, text: qsTr("Down") }
    ]
}

function keyboardProfiles(text) {
    var profiles = {}
    try {
        var saved = JSON.parse(text)
        if (!saved || typeof saved !== "object" || Array.isArray(saved)) return profiles
        var keys = keyboardOptions().map(function(option) { return option.value })
        for (var channel = 1; channel <= 18; ++channel) {
            if (typeof saved[channel] !== "string") continue
            var ranges = parse(saved[channel])
            if (valid(ranges, keys) && ranges.some(function(range) { return range.value !== 0 }))
                profiles[channel] = ranges
        }
    } catch (error) {
        return {}
    }
    return profiles
}

function encodeKeyboardProfiles(profiles) {
    var saved = {}
    Object.keys(profiles).forEach(function(channel) { saved[channel] = encode(profiles[channel]) })
    return JSON.stringify(saved)
}

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

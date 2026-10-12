.pragma library
// Relative preview only; this is not a calibrated sensor CCT conversion.
function gains(temperature, red, green, blue) {
    var warmth = Math.sqrt(Math.max(2000, Math.min(12000, temperature)) / 6500);
    return Qt.vector3d(red * warmth, green, blue / warmth);
}

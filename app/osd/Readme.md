# Summary
All files here are OSD elements that are written in c++ (though they might have corresponding qml files under qml/widgets ? \
The reason they were written in c++ is Performance (pretty sure on this one).
They generally all inherit from QQuickPaintedItem and draw stuff via QPainter.

Note that only a small number of OSD elements is done in c++, the rest is qml.

# NOTE
After a bit of refactoring, I managed to get rid of all external dependencies here - please keep it this way
(these classes use sett-ers with standard data types to consume telemetry data changes).
I am pretty sure the registering of callbacks is done in qml



Generally, we have 2 OpenHD systems (each wth their own unique mavlink system id and one or more component(s) 
and the FC system (if connected)

Note: r.n these classes are basically only models that expose (fire and forget) telemetry data coming from the OHD air / ground unit to qt.
Not sure if it makes sense to change that design-wise.

Also, they share quite a bit of common code - but I don't know how qt deals with memeber(s) on inheritance

Note, however, that talking to the OpenHD Air unit requires the Ground unit in between,
and talking to the FC requires both OpenHD Air and Ground unit(s) in between.
(Just send the message to the OHD Ground unit, OpenHD will do the forwarding)

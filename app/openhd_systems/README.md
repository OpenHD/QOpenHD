Generally, we have 2 OpenHD systems (each wth their own unique mavlink system id and one or more component(s) 
and the FC system (if connected)

Note, however, that talking to the OpenHD Air unit requires the Ground unit in between,
and talking to the FC requires both OpenHD Air and Ground unit(s) in between.
(Just send the message to the OHD Ground unit, OpenHD will do the forwarding)

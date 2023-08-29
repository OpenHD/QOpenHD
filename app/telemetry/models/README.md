NOTE: Code in here is strictly mavlink broadcast - aka no retransmission or quaranteed deliveries.
NOTE: See action and / or settings subdirectories for code that 'talks' to one or more of the mavlink systems.

Generally, we have 2 OpenHD systems (each wth their own unique mavlink system id and one or more component(s) 
and the FC system (if connected)

The OpenHD air and ground unit are quite similar in their functionalities, at least in regards to their "fire and forget" mavlink telemetry data.
(For example, air and ground both report the CPU usage the same way).
That's why there is one class to handle them both, with slight differences (for example, air has no video rx-es and similar).
It would be nicer from a developer perspective to have one common "shared" base class and 2 different impl. for air and ground,
but unfortunately qt and their modeling / signal stuff doesn't work with inheritance.

For the one and only FC (the FC connected to the Air unit, but for which OpenHD provides direct access to) we also have a model (quite dirty right now).


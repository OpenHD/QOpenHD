# Qt Creator menu preview

Launch QOpenHD using Qt Creator's Run or Debug action. In the Advanced menu,
click the bug icon immediately left of Refresh. Its highlighted state means
menu preview is active; click again to restore normal visibility.

The button and backend activation are gated by Qt Creator process ancestry.
A debug build, a manually launched binary, or attaching a debugger does not
by itself enable it. If the launcher ancestry cannot be established (for example
some remote launch arrangements), the button stays hidden.

Preview is session-only. It reveals platform and feature rows, every link card,
both camera selectors, raw parameter groups, and representative storage states.
Sample parameter rows use the bundled catalog in a separate display model.
Actual parameter caches and the saved advanced-settings flags are retained.
Parameter writes/refetches are blocked while previewing; storage and power
actions are disabled. Normal navigation and tab/category selection remain active.

The preview combines mutually exclusive hardware controls for layout inspection.
It does not emulate firmware capabilities, detected cameras, microphone lists,
FleetControl accounts, or live telemetry. Choice lists requiring those sources
may be empty. Production visibility is restored when preview is switched off.

# Shared advanced-menu style

`qml/ui/configpopup/MenuTypography.js` is the single source for menu typography and standard control dimensions. Values are logical pixels; the existing outer window/menu scaling handles display density.

| Role | Logical pixels |
| --- | --- |
| Page title | 28 |
| Dialog title | 21 |
| Section/card heading | 16 |
| Body, labels, values and buttons | 13 |
| Supporting descriptions/status | 11 |
| Prominent telemetry metric | 22 |

Standard actions, dialog actions, tabs, dropdowns and inputs use a 38 px control height. Standard action padding is 14 px horizontally, with an 8 px radius; widths fit labels or the containing layout. Category/preview tiles retain their content layout rather than taking action-button dimensions.

General and Map use the same role sizes and action component as the other menu pages. Status details, camera, storage, link, application, connection and developer views also use these shared roles. The actual OSD widgets and native OSD font previews keep their own user-selected rendering.

`tests/check_menu_style.py` prevents new per-page font numbers/offsets. `tests/menu_style` checks matching runtime text roles and control heights across action/dialog/map/tab components. Existing responsive and navigation suites cover clipping, scaling and page behavior.

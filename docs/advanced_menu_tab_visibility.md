# Advanced menu tab availability

Parameter-only tabs/categories are shown only when they have settings visible
in the current normal, advanced or developer mode. The parent Camera, Air and
Ground tabs use their models without loading hidden pages. Camera categories
share their classification and mode filter with the parent tab.

An empty category has no selection. When the selected category disappears,
selection falls back to the first available category. Parameter updates and
mode changes update availability; selection handlers and keyboard navigation
use the same rules as button visibility. Preview fixture data also needs content.

Shared `AdvancedTabButton` / `AdvancedTabBar` controls use `hasContent` for
availability. This is independent of effective `visible`, so hiding the whole
page does not change its selection. Shared bars skip unavailable buttons and
use index -1 when all tabs are empty. Log sources use their row counts; unsupported
Data Link settings are hidden. Pages with local controls/actions or useful
status remain accessible without connected hardware.

Checks:

```powershell
python tests/run_empty_tabs_test.py --qt-bin C:/Qt/5.15.19/mingw81_64/bin
python tests/run_empty_tabs_test.py --qt-bin C:/Qt/6.9.1/mingw_64/bin
```

The Air settings and advanced-menu loading suites also cover category model
updates, mode gating and asynchronous menu navigation. These are local UI
regressions, not device/RF validation.

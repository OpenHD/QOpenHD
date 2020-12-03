import QtQuick 2.12

/*
 * These are mappings for the raw parameter key/value pairs from the drone. We
 * give certain parameters full readable titles, type information, and limits or
 * ranges in order to make them more visible and easier to deal with. We also allow
 * specific settings to place constraints on other settings so that conflicting or
 * invalid configurations can be prevented.
 *
 */
Item {
    id: ardupilotParameterMap

    property var generalParameterMap: ({

    })

    // these parameters wont show up at all
    property var blacklistMap: ({

    })

    // these parameters will simply be disabled and uneditable in the UI
    property var disabledMap: ({

    })
}

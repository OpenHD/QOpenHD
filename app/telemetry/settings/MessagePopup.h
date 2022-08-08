#ifndef MESSAGEPOPUP_H
#define MESSAGEPOPUP_H

// QT Message popup's (their default ones) don't work in kms, since they are opened in a new window.
//

#include <QMessageBox>

namespace workaround{

// Show a message to the user he can only remove by clicking "OK".

static void makePopupMessage(QString message){
    QMessageBox msgBox;
    msgBox.setText(message);
    msgBox.exec();
}

}

#endif // MESSAGEPOPUP_H

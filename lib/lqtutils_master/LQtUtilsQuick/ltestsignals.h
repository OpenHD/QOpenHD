#ifndef LTESTSIGNALS_H
#define LTESTSIGNALS_H

#include <QObject>

#include <../lqtutils_enum.h>

L_DECLARE_ENUM(MySharedEnum,
               Value1,
               Value2,
               Value6 = 6)

Q_NAMESPACE

class LTestSignals : public QObject
{
    Q_OBJECT
public:
    explicit LTestSignals(QObject* parent = nullptr);
};

#endif // LTESTSIGNALS_H

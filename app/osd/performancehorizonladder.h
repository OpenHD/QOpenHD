#ifndef PERFORMANCEHORIZONLADDER_H
#define PERFORMANCEHORIZONLADDER_H

#include <QQuickItem>
#include <QSGGeometryNode>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"

#include "horizonladder.h"

class PerformanceHorizonLadder : public QQuickItem
{
    Q_OBJECT
public:
     PerformanceHorizonLadder(QQuickItem *parent = nullptr);
    ~ PerformanceHorizonLadder();

     Q_PROPERTY(int pitch MEMBER m_pitch WRITE setPitch NOTIFY pitchChanged)
     Q_PROPERTY(int roll MEMBER m_roll WRITE setRoll NOTIFY rollChanged)
     //
     void setRoll(int roll);
     void setPitch(int pitch);
signals:
     void rollChanged(int roll);
     void pitchChanged(int pitch);
    // QQuickItem interface
protected:
    QSGNode *updatePaintNode(QSGNode *n, UpdatePaintNodeData *) override;

private:
    QSGGeometryNode *node=nullptr;
    QSGTransformNode* m_tf_node=nullptr;
    QSGTransformNode* m_tf_node2=nullptr;
	QSGTransformNode* m_tf_node3=nullptr;
private:
    int m_roll;
    int m_pitch;
private:
    HorizonLadder* m_hl=nullptr;
};

#endif // PERFORMANCEHORIZONLADDER_H

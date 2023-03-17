#include "performancehorizonladder.h"

#include <QSGFlatColorMaterial>
#include <QMatrix>
#include <qtransform.h>

PerformanceHorizonLadder::PerformanceHorizonLadder(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlags(ItemHasContents);
}

PerformanceHorizonLadder::~PerformanceHorizonLadder()
{

}

void PerformanceHorizonLadder::setRoll(int roll) {
    m_roll = roll;
    emit rollChanged(m_roll);
    update();
}


void PerformanceHorizonLadder::setPitch(int pitch) {
    m_pitch = pitch;
    emit pitchChanged(m_pitch);
    update();
}


static QSGGeometry* make_rectangle(int height,int width){
    QSGGeometry *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 4);
    geometry->setDrawingMode(GL_LINES);
    geometry->setLineWidth(10);
    geometry->vertexDataAsPoint2D()[0].set(0, 0);
    geometry->vertexDataAsPoint2D()[1].set(0,width);
    geometry->vertexDataAsPoint2D()[2].set(height,width);
    geometry->vertexDataAsPoint2D()[3].set(height,0);
    return geometry;
}

static QSGGeometry* make_line(int width,int height){
    QSGGeometry *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 2);
    geometry->setDrawingMode(GL_LINES);
    geometry->setLineWidth(10);
    geometry->vertexDataAsPoint2D()[0].set(0, height/2); //height/2
    geometry->vertexDataAsPoint2D()[1].set(width,height/2);
    return geometry;
}

QSGNode *PerformanceHorizonLadder::updatePaintNode(QSGNode *n, QQuickItem::UpdatePaintNodeData *)
{
    if(!node){
        node = new QSGGeometryNode();
        m_tf_node = new QSGTransformNode();

        //auto geometry=make_rectangle(width(),height());
        auto geometry=make_line(width(),height());

        QSGFlatColorMaterial *material = new QSGFlatColorMaterial();
        material->setColor(QColor(255, 0, 0));

        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);

        m_tf_node->appendChildNode(node);
    }
    //qDebug()<<"LOOOL";

    QRectF rect(boundingRect());

    //QSGGeometry::updateColoredRectGeometry(node->geometry(),rect);
    //QSGGeometry::updateTexturedRectGeometry(node->geometry(), rect, texture_coords);
    node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);

    auto matrix=QMatrix4x4();
    matrix.rotate(QQuaternion::fromAxisAndAngle(QVector3D(0,0,1),m_roll*-1));
    //matrix.translate({0.0f,m_pitch*18.0f,0.0f});
    m_tf_node->setMatrix(matrix);
    //QTransform transform_centerOfWindow( 1, 0, 0, 1, width()/2, height()/2 );
    //transform_centerOfWindow.rotate(m_pitch*18.0f);


    //QMetaObject::invokeMethod(node, "update", Qt::QueuedConnection);
    //return node;
    return m_tf_node;
}

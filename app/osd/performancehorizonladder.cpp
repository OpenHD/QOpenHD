#include "performancehorizonladder.h"

#include <QSGFlatColorMaterial>
#include <QMatrix>
#include <qtransform.h>

PerformanceHorizonLadder::PerformanceHorizonLadder(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlags(ItemHasContents);
    setClip(false);
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

struct Vec2{
    float x=0;
    float y=0;
};
static void append_horizontal_line_with_middle_space(std::vector<Vec2>& buff,float width,float y_off,float middle_space,float height){
    const float middle_space_half=middle_space/2;
    //left up line
    buff.push_back({0,y_off});
    buff.push_back({0,y_off+height});
    //left to middle
    buff.push_back({0,y_off});
    buff.push_back({width/2.0f-middle_space_half,y_off});
    // middle to right
    buff.push_back({width/2.0f+middle_space_half,y_off});
     buff.push_back({width,y_off});
    // right up
    buff.push_back({width,y_off});
    buff.push_back({width,y_off+height});
}
static void append_horizontal_line(std::vector<Vec2>& buff,float width,float y_off){
    buff.push_back({0,y_off});
    buff.push_back({width,y_off});
}

static QSGGeometry* qsggeometry_from_array(const std::vector<Vec2>& vec){
     QSGGeometry *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), vec.size());
     for(int i=0;i<vec.size();i++){
         geometry->vertexDataAsPoint2D()[i].set(vec[i].x,vec[i].y);
     }
     geometry->setDrawingMode(GL_LINES);
     geometry->setLineWidth(1);
     return geometry;
}

static QSGGeometry* make_line(int width,int height){
    QSGGeometry *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 2);
    geometry->setDrawingMode(GL_LINES);
    geometry->setLineWidth(3);
    /*geometry->vertexDataAsPoint2D()[0].set(-width/2, 0); //height/2
    geometry->vertexDataAsPoint2D()[1].set(width/2,0);*/
    geometry->vertexDataAsPoint2D()[0].set(0, height/2); //height/2
    geometry->vertexDataAsPoint2D()[1].set(width,height/2);
    return geometry;
}

QSGNode *PerformanceHorizonLadder::updatePaintNode(QSGNode *n, QQuickItem::UpdatePaintNodeData *)
{
    if(!node){
        node = new QSGGeometryNode();
        m_tf_node = new QSGTransformNode();
        m_tf_node2 = new QSGTransformNode();
        m_tf_node3 = new QSGTransformNode();

        //auto geometry=make_rectangle(width(),height());
        //auto geometry=make_line(width(),height());
        auto vertices=std::vector<Vec2>();
        append_horizontal_line(vertices,width(),height()/2);
        append_horizontal_line_with_middle_space(vertices,width(),height()/4,width()/10,height()/20);
        //append_horizontal_line_with_middle_space(vertices,width(),width()/2,height()/10,-height()/2);

        auto geometry=qsggeometry_from_array(vertices);

        QSGFlatColorMaterial *material = new QSGFlatColorMaterial();
        material->setColor(QColor(255, 255, 255));

        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);

        m_tf_node->appendChildNode(m_tf_node2);
        m_tf_node2->appendChildNode(m_tf_node3);
        m_tf_node3->appendChildNode(node);

    }
    //qDebug()<<"LOOOL";

    QRectF rect(boundingRect());

    //QSGGeometry::updateColoredRectGeometry(node->geometry(),rect);
    //QSGGeometry::updateTexturedRectGeometry(node->geometry(), rect, texture_coords);
    node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);

    /*{
        auto matrix=QMatrix4x4();
        matrix.setToIdentity();
        matrix.translate({0.0f,m_pitch*18.0f,0.0f});
        m_tf_node->setMatrix(matrix);
    }
    {
        auto matrix=QMatrix4x4();
        matrix.setToIdentity();
        matrix.rotate(m_roll*-1,QVector3D(0,0,1));
        m_tf_node2->setMatrix(matrix);
    }
    {
        auto matrix=QMatrix4x4();
        matrix.setToIdentity();
        matrix.translate(width()/2,height()/2,0);
        m_tf_node3->setMatrix(matrix);
    }*/
    {
        auto matrix=QMatrix4x4();
        matrix.setToIdentity();
        matrix.translate(width()/2,height()/2,0);
        matrix.rotate(m_roll*-1,QVector3D(0,0,1));
        matrix.translate(-width()/2,-height()/2,0);

        matrix.translate({0.0f,m_pitch*18.0f,0.0f});
        m_tf_node->setMatrix(matrix);
    }

    //QTransform transform_centerOfWindow( 1, 0, 0, 1, width()/2, height()/2 );
    //transform_centerOfWindow.rotate(m_pitch*18.0f);


    //QMetaObject::invokeMethod(node, "update", Qt::QueuedConnection);
    //return node;
    return m_tf_node;
}

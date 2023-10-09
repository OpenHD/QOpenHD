#include "performancehorizonladder.h"

#include <QSGFlatColorMaterial>
#include <QMatrix>
#include <math.h>
#include <qtransform.h>

PerformanceHorizonLadder::PerformanceHorizonLadder(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlags(ItemHasContents);
    setClip(false);
}

PerformanceHorizonLadder::~PerformanceHorizonLadder()
{
    if(m_base_node){
        delete m_base_node;
    }
    if(m_center_indicator){
        delete m_center_indicator;
    }
    if(m_ladders_geom_node){
        delete m_ladders_geom_node;
    }
    if(m_tf_node){
        delete m_tf_node;
    }
    if(m_flat_color_material){
        delete m_flat_color_material;
    }
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
static void append_horizontal_line_with_middle_space(std::vector<Vec2>& buff,float x_off,float width,float y_off,float middle_space,float height){
    const float middle_space_half=middle_space/2;
    //left up line
    buff.push_back({x_off+0,y_off});
    buff.push_back({x_off+0,y_off+height});
    //left to middle
    buff.push_back({x_off+0,y_off});
    buff.push_back({x_off+width/2.0f-middle_space_half,y_off});
    // middle to right
    buff.push_back({x_off+width/2.0f+middle_space_half,y_off});
     buff.push_back({x_off+width,y_off});
    // right up
    buff.push_back({x_off+width,y_off});
    buff.push_back({x_off+width,y_off+height});
}
static void append_horizontal_line_with_middle_space_and_dashes(std::vector<Vec2>& buff,float x_off,float width,float y_off,float middle_space,float height){
    const float middle_space_half=middle_space/2;
    const float horizontal_line_length=width/2.0f-middle_space_half;
    const float dash_length=horizontal_line_length/5.0f;
    //left down line
    buff.push_back({x_off+0,y_off});
    buff.push_back({x_off+0,y_off-height});
    //left to middle,dashes
    int count=0;
    for(int i=0;i<3;i++){
        buff.push_back({x_off+dash_length*count,y_off});
        count++;
        buff.push_back({x_off+dash_length*count,y_off});
        count++;
    }
    // middle to right
    count=0;
    for(int i=0;i<3;i++){
        const float start=x_off+width/2.0f+middle_space_half;
        buff.push_back({start+dash_length*count,y_off});
        count++;
        buff.push_back({start+dash_length*count,y_off});
        count++;
    }
    // right down line
    buff.push_back({x_off+width,y_off});
    buff.push_back({x_off+width,y_off-height});
}

static void append_horizontal_line(std::vector<Vec2>& buff,float x,float y,float width){
    buff.push_back({x,y});
    buff.push_back({x+width,y});
}

static std::vector<Vec2> make_circle(int segments,float center_x,float center_y,float radius){
    std::vector<Vec2> vertices;
    float step = 6.283185f/segments;
    float angle = 0.0f;

    vertices.reserve(segments + 1);
    for (int i = 0; i < segments; ++i, angle+=step) {
        float vertX = center_x + cosf(angle)*radius;
        float vertY = center_y + sinf(angle)*radius;
        vertices.push_back({vertX, vertY});
    }
    vertices.push_back({center_x+radius, center_y});
    return vertices;
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
    if(!m_base_node){
        m_base_node = new QSGNode();
        m_ladders_geom_node = new QSGGeometryNode();
        m_tf_node = new QSGTransformNode();
        m_center_indicator = new QSGGeometryNode();

        m_flat_color_material = new QSGFlatColorMaterial();
        m_flat_color_material->setColor(QColor(255, 255, 255));

        const auto m_width=width();
        const auto m_height=height();

        {
            //auto geometry=make_rectangle(width(),height());
            //auto geometry=make_line(width(),height());
            auto vertices=std::vector<Vec2>();
            // the middle, big line
            append_horizontal_line(vertices,0,height()/2,width());
            // lower/ upper lines
            const auto l_width=m_width * 0.6f;
            const auto l_x_offset= m_width/2.0f-l_width/2.0f;
            // upper lines
            for(int i=1;i<9;i++){ //9 = 9 times 10 degree
                const auto l_y_offset=height()/2.0f-height()/2.0f*i*1.2;
                append_horizontal_line_with_middle_space(vertices,l_x_offset,l_width,l_y_offset,width()/4.0f,height()/30.0f);
            }
            // lower lines
            for(int i=1;i<9;i++){  //9 = 9 times 10 degree
                const auto l_y_offset=height()/2.0f+height()/2.0f*i*1.2;
                append_horizontal_line_with_middle_space_and_dashes(vertices,l_x_offset,l_width,l_y_offset,width()/4.0f,height()/20.0f);
            }
            //append_horizontal_line_with_middle_space(vertices,width(),width()/2,height()/10,-height()/2);

            auto geometry=qsggeometry_from_array(vertices);

            m_ladders_geom_node->setGeometry(geometry);
            m_ladders_geom_node->setFlag(QSGNode::OwnsGeometry);
            m_ladders_geom_node->setMaterial(m_flat_color_material);
            m_ladders_geom_node->setFlag(QSGNode::OwnsMaterial);
        }
        {
            //auto vertices=std::vector<Vec2>();
            //const auto center_line_width=width()/8;
            //append_horizontal_line(vertices,width()/2.0f-center_line_width/2.0f,height()/2,center_line_width);
            const auto radius=width()/38;
            auto vertices = make_circle(20,width()/2,height()/2,radius);
            auto geometry=qsggeometry_from_array(vertices);
            geometry->setDrawingMode(GL_LINE_STRIP);
            geometry->setLineWidth(1);
            m_center_indicator->setGeometry(geometry);
            m_center_indicator->setFlag(QSGNode::OwnsGeometry);
            m_center_indicator->setMaterial(m_flat_color_material);
            m_center_indicator->setFlag(QSGNode::OwnsMaterial);
        }

        m_base_node->appendChildNode(m_tf_node);
        m_base_node->appendChildNode(m_center_indicator);
        m_tf_node->appendChildNode(m_ladders_geom_node);
    }
    //qDebug()<<"LOOOL";

    QRectF rect(boundingRect());

    //QSGGeometry::updateColoredRectGeometry(node->geometry(),rect);
    //QSGGeometry::updateTexturedRectGeometry(node->geometry(), rect, texture_coords);
    m_ladders_geom_node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);

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
    return m_base_node;
}

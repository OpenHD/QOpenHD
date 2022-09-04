#include "texturerenderer.h"
#include <QtQuick/qquickwindow.h>
#include <QOpenGLShaderProgram>
#include <QOpenGLContext>
#include <QtCore/QRunnable>

#include <cmath>

/// negative x,y is bottom left and first vertex
//Consti10: Video was flipped horizontally (at least big buck bunny)
static const GLfloat vertices[][4][3] =
    {
        { {-1.0, -1.0, 0.0}, { 1.0, -1.0, 0.0}, {-1.0, 1.0, 0.0}, {1.0, 1.0, 0.0} }
    };
static const GLfloat uv_coords[][4][2] =
    {
        //{ {0.0, 0.0}, {1.0, 0.0}, {0.0, 1.0}, {1.0, 1.0} }
        { {1.0, 1.0}, {0.0, 1.0}, {1.0, 0.0}, {0.0, 0.0} }
    };


TextureRenderer::~TextureRenderer()
{
    delete m_program;
    glDeleteBuffers(1, &vbo);
}
//! [6]

//! [4]
void TextureRenderer::init()
{
    if (!m_program) {
        QSGRendererInterface *rif = m_window->rendererInterface();
        Q_ASSERT(rif->graphicsApi() == QSGRendererInterface::OpenGL);

        initializeOpenGLFunctions();

        m_program = new QOpenGLShaderProgram();
        m_program->addCacheableShaderFromSourceCode(QOpenGLShader::Vertex,
                                                    "attribute vec3 position;\n"
                                                    "attribute vec2 tx_coords;\n"
                                                    "varying vec2 v_texCoord;\n"
                                                    "void main() {  \n"
                                                    "	gl_Position = vec4(position, 1.0);\n"
                                                    "	v_texCoord = tx_coords;\n"
                                                    "}\n");
        //"	gl_FragColor = texture2D( texture, v_texCoord );\n"
        //"	gl_FragColor = vec4(0.0,1.0,0.0,1.0);\n"
        m_program->addCacheableShaderFromSourceCode(QOpenGLShader::Fragment,
                                                    "precision mediump float;\n"
                                                    "uniform sampler2D texture;\n"
                                                    "varying vec2 v_texCoord;\n"
                                                    "void main() {	\n"
                                                    "	gl_FragColor = texture2D( texture, v_texCoord );\n"
                                                    "}\n");
        m_program->link();
        //
        const int test_w=640;
        const int test_h=480;
        QImage image1{test_w,test_h, QImage::Format_RGB888};
        image1.fill(QColor(255, 0, 0));
        QImage image2{test_w,test_h, QImage::Format_RGB888};
        image2.fill(QColor(0, 255, 0));

        /*QImage image1{QString(":/resources/ic128.png")};
        image1=image1.mirrored();
        QImage image2{QString(":/resources/ic128.png")};*/

        texture1=std::make_unique<QOpenGLTexture>(image1);
        texture2=std::make_unique<QOpenGLTexture>(image2);
        m_program->setUniformValue("texture", 0);
        pos = m_program->attributeLocation( "position");
        uvs = m_program->attributeLocation( "tx_coords");

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices)+sizeof(uv_coords), 0, GL_STATIC_DRAW);
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices);
        glBufferSubData(GL_ARRAY_BUFFER, sizeof(vertices), sizeof(uv_coords), uv_coords);
        glEnableVertexAttribArray(pos);
        glEnableVertexAttribArray(uvs);
        glVertexAttribPointer(pos, 3, GL_FLOAT, GL_FALSE, 0, (GLvoid*)0);
        glVertexAttribPointer(uvs, 2, GL_FLOAT, GL_FALSE, 0, (GLvoid*)sizeof(vertices)); /// last is offset to loc in buf memory
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
}

//! [4] //! [5]
void TextureRenderer::paint()
{
     const auto delta=std::chrono::steady_clock::now()-last_frame;
     last_frame=std::chrono::steady_clock::now();
     const auto frame_time_us=std::chrono::duration_cast<std::chrono::microseconds>(delta).count();
     const float frame_time_ms=((float)frame_time_us)/1000.0f;
     qDebug()<<" SquircleRenderer::paint() frame time:"<<frame_time_ms<<"ms";
     renderCount++;
     if(renderCount>1){
         renderCount=0;
     }

    // Play nice with the RHI. Not strictly needed when the scenegraph uses
    // OpenGL directly.
    m_window->beginExternalCommands();

    m_program->bind();

    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glEnableVertexAttribArray(pos);
    glEnableVertexAttribArray(uvs);
    glVertexAttribPointer(pos, 3, GL_FLOAT, GL_FALSE, 0, (GLvoid*)0);
    glVertexAttribPointer(uvs, 2, GL_FLOAT, GL_FALSE, 0, (GLvoid*)sizeof(vertices)); /// last is offset to loc in buf memory
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    // r.n we just swap between 2 textures
     QOpenGLTexture *texture;
     if(renderCount==0){
         texture=texture1.get();
     }else{
         texture=texture2.get();
     }
     glBindTexture(GL_TEXTURE_2D, texture->textureId());

     // We setup the viewport surch that we preserve the original ratio of the teture ( width / height).
     // One could also just transform the vertex coordinates, but setting the vieport accordingly is easier.
     const int surface_width=m_viewportSize.width();
     const int surface_height=m_viewportSize.height();
     const double surface_aspect_ratio=(double)surface_width / (double)surface_height;
     const int texture_width=texture->width();
     const int texture_height=texture->height();
     const double texture_aspect_ratio=(double)texture_width / (double)texture_height;
     qDebug()<<"Surface "<< surface_width<<"x"<<surface_height<<" ratio:"<<surface_aspect_ratio;
     qDebug()<<"Texture "<<texture_width<<"x"<<texture_height<<" ratio:"<<texture_aspect_ratio;
     int x_viewport_width=0;
     int x_viewport_height=0;
     if(surface_aspect_ratio>texture_aspect_ratio){
         // we use the full height, and andjust the width.
         // Example case: 16/9 (1.7) surface  and 4:3 (1.3) (video) texture
         x_viewport_height=surface_height;
         auto tmp= surface_height * texture_aspect_ratio;
         x_viewport_width=std::lround(tmp);
         int x_offset=(m_viewportSize.width()-x_viewport_width)/2;
         qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
         glViewport(x_offset,0,x_viewport_width,x_viewport_height);
     }else{
          // we use the full width, and adjust the height
         x_viewport_width=surface_width;
         auto tmp= surface_width * (1.0/texture_aspect_ratio);
         x_viewport_height=std::lround(tmp);
         int y_offset=(m_viewportSize.height()-x_viewport_height)/2;
          qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
          glViewport(0,y_offset,x_viewport_width,x_viewport_height);
     }
     //glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

     glDisable(GL_DEPTH_TEST);

     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

     m_program->release();
     //texture->release();
     glBindTexture(GL_TEXTURE_2D, 0);
     // make sure we leave how we started / such that Qt rendering works normally
     glEnable(GL_DEPTH_TEST);
     glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

    m_window->endExternalCommands();
}
//! [5]

#include "texturerenderer.h"
#include <QtQuick/qquickwindow.h>
#include <QOpenGLShaderProgram>
#include <QOpenGLContext>

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
    //delete m_program;
    //glDeleteBuffers(1, &vbo);
}
//! [6]

//! [4]
void TextureRenderer::init()
{
    if (!initialized) {
        initialized=true;
        QSGRendererInterface *rif = m_window->rendererInterface();
        Q_ASSERT(rif->graphicsApi() == QSGRendererInterface::OpenGL);

        initializeOpenGLFunctions();
        gl_shaders=std::make_unique<GL_shaders>();
        gl_shaders->initialize();

        //
        const int test_w=1280;
        const int test_h=900;
        QImage image1{test_w,test_h, QImage::Format_RGB888};
        image1.fill(QColor(255, 0, 0));
        QImage image2{test_w,test_h, QImage::Format_RGB888};
        image2.fill(QColor(0, 255, 0));

        /*QImage image1{QString(":/resources/ic128.png")};
        image1=image1.mirrored();
        QImage image2{QString(":/resources/ic128.png")};*/

        texture1=std::make_unique<QOpenGLTexture>(image1);
        texture2=std::make_unique<QOpenGLTexture>(image2);
    }
}

//! [4] //! [5]
void TextureRenderer::paint()
{
    const auto delta=std::chrono::steady_clock::now()-last_frame;
    last_frame=std::chrono::steady_clock::now();
    const auto frame_time_us=std::chrono::duration_cast<std::chrono::microseconds>(delta).count();
    const float frame_time_ms=((float)frame_time_us)/1000.0f;
    //qDebug()<<" TextureRenderer::paint() frame time:"<<frame_time_ms<<"ms";
    renderCount++;

   // Play nice with the RHI. Not strictly needed when the scenegraph uses
   // OpenGL directly.
    // Consti10: comp error, seems to work without, too
   m_window->beginExternalCommands();
   //glClear(GL_COLOR_BUFFER_BIT |GL_DEPTH_BUFFER_BIT| GL_STENCIL_BUFFER_BIT);

   // r.n we just swap between 2 textures
   QOpenGLTexture *texture;
   if((renderCount/1) % 2==0){
       texture=texture1.get();
   }else{
       texture=texture2.get();
   }
    // We setup the viewport surch that we preserve the original ratio of the teture ( width / height).
    // One could also just transform the vertex coordinates, but setting the vieport accordingly is easier.
    const int surface_width=m_viewportSize.width();
    const int surface_height=m_viewportSize.height();
    const double surface_aspect_ratio=(double)surface_width / (double)surface_height;
    const int texture_width=texture->width();
    const int texture_height=texture->height();
    const double texture_aspect_ratio=(double)texture_width / (double)texture_height;
    //qDebug()<<"Surface "<< surface_width<<"x"<<surface_height<<" ratio:"<<surface_aspect_ratio;
    //qDebug()<<"Texture "<<texture_width<<"x"<<texture_height<<" ratio:"<<texture_aspect_ratio;
    int x_viewport_width=0;
    int x_viewport_height=0;
    if(surface_aspect_ratio>texture_aspect_ratio){
        // we use the full height, and andjust the width.
        // Example case: 16/9 (1.7) surface  and 4:3 (1.3) (video) texture
        x_viewport_height=surface_height;
        auto tmp= surface_height * texture_aspect_ratio;
        x_viewport_width=std::lround(tmp);
        int x_offset=(m_viewportSize.width()-x_viewport_width)/2;
        //qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
        glViewport(x_offset,0,x_viewport_width,x_viewport_height);
    }else{
         // we use the full width, and adjust the height
        x_viewport_width=surface_width;
        auto tmp= surface_width * (1.0/texture_aspect_ratio);
        x_viewport_height=std::lround(tmp);
        int y_offset=(m_viewportSize.height()-x_viewport_height)/2;
         //qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
         glViewport(0,y_offset,x_viewport_width,x_viewport_height);
    }
    //glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

    glDisable(GL_DEPTH_TEST);

    gl_shaders->draw_rgb(texture->textureId());
    //gl_shaders->draw_YUV420P(texture->textureId(),texture->textureId(),texture->textureId());

    // make sure we leave how we started / such that Qt rendering works normally
    glEnable(GL_DEPTH_TEST);
    glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

    m_window->endExternalCommands();
}
//! [5]

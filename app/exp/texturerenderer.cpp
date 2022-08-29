#include "texturerenderer.h"
#include <QtQuick/qquickwindow.h>
#include <QOpenGLShaderProgram>
#include <QOpenGLContext>
#include <QtCore/QRunnable>

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
        texture=new QOpenGLTexture(QImage(QString(":/resources/ic128.png")).mirrored());
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

    texture->bind();

    glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

    glDisable(GL_DEPTH_TEST);

    //glEnable(GL_BLEND);
    //glBlendFunc(GL_SRC_ALPHA, GL_ONE);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    m_program->release();
    texture->release();

    m_window->endExternalCommands();
}
//! [5]

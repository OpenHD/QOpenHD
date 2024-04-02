#include "qsurfacetexture.h"

#include <QAndroidJniEnvironment>
#include <QSGGeometryNode>
#include <QSGSimpleMaterialShader>

#include "vscommon/QOpenHDVideoHelper.hpp"
#include "vscommon/video_ratio_helper.hpp"

struct State {
    // the texture transform matrix
    QMatrix4x4 uSTMatrix;
    GLuint textureId = 0;

    int compare(const State *other) const
    {
        return (uSTMatrix == other->uSTMatrix && textureId == other->textureId) ? 0 : -1;
    }
};

class SurfaceTextureShader : QSGSimpleMaterialShader<State>
{
    QSG_DECLARE_SIMPLE_COMPARABLE_SHADER(SurfaceTextureShader, State)
public:
    // vertex & fragment shaders are shamelessly "stolen" from MyGLSurfaceView.java :)
    const char *vertexShader() const override {
        return
                "uniform mat4 qt_Matrix;                            \n"
                "uniform mat4 uSTMatrix;                            \n"
                "attribute vec4 aPosition;                          \n"
                "attribute vec4 aTextureCoord;                      \n"
                "varying vec2 vTextureCoord;                        \n"
                "void main() {                                      \n"
                "  gl_Position = qt_Matrix * aPosition;             \n"
                "  vTextureCoord = (uSTMatrix * aTextureCoord).xy;  \n"
                "}";
    }

    const char *fragmentShader() const override {
        return
                "#extension GL_OES_EGL_image_external : require                     \n"
                "precision mediump float;                                           \n"
                "varying vec2 vTextureCoord;                                        \n"
                "uniform lowp float qt_Opacity;                                     \n"
                "uniform samplerExternalOES sTexture;                               \n"
                "void main() {                                                      \n"
                "  gl_FragColor = texture2D(sTexture, vTextureCoord) * qt_Opacity;  \n"
                "}";
    }

    QList<QByteArray> attributes() const override
    {
        return QList<QByteArray>() << "aPosition" << "aTextureCoord";
    }

    void updateState(const State *state, const State *) override
    {
        program()->setUniformValue(m_uSTMatrixLoc, state->uSTMatrix);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, state->textureId);
    }

    void resolveUniforms() override
    {
        m_uSTMatrixLoc = program()->uniformLocation("uSTMatrix");
        program()->setUniformValue("sTexture", 0); // we need to set the texture once
    }

private:
    int m_uSTMatrixLoc;
};

class SurfaceTextureNode : public QSGGeometryNode
{
public:
    SurfaceTextureNode(const QAndroidJniObject &surfaceTexture, GLuint textureId)
        : QSGGeometryNode()
        , m_surfaceTexture(surfaceTexture)
        , m_geometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4)
        , m_textureId(textureId)
    {
        // we're going to use "preprocess" method to update the texture image
        // and to get the new matrix.
        setFlag(UsePreprocess);

        setGeometry(&m_geometry);

        // Create and set our SurfaceTextureShader
        QSGSimpleMaterial<State> *material = SurfaceTextureShader::createMaterial();
        material->state()->textureId = m_textureId;
        material->setFlag(QSGMaterial::Blending, false);
        setMaterial(material);
        setFlag(OwnsMaterial);

        // We're going to get the transform matrix for every frame
        // so, let's create the array once
        QAndroidJniEnvironment env;
        jfloatArray array = env->NewFloatArray(16);
        m_uSTMatrixArray = jfloatArray(env->NewGlobalRef(array));
        env->DeleteLocalRef(array);
    }

    ~SurfaceTextureNode() override
    {
        // delete the global reference, now the gc is free to free it
        QAndroidJniEnvironment()->DeleteGlobalRef(m_uSTMatrixArray);
    }

    // QSGNode interface
    void preprocess() override;

private:
    QAndroidJniObject m_surfaceTexture;
    QSGGeometry m_geometry;
    jfloatArray m_uSTMatrixArray = nullptr;
    GLuint m_textureId;
};

void SurfaceTextureNode::preprocess()
{
    auto mat = static_cast<QSGSimpleMaterial<State> *>(material());
    if (!mat)
        return;

    // update the texture content
    m_surfaceTexture.callMethod<void>("updateTexImage");

    // get the new texture transform matrix
    m_surfaceTexture.callMethod<void>("getTransformMatrix", "([F)V", m_uSTMatrixArray);
    QAndroidJniEnvironment env;
    env->GetFloatArrayRegion(m_uSTMatrixArray, 0, 16, mat->state()->uSTMatrix.data());
}


/*extern "C" void Java_org_openhd_SurfaceTextureListener_frameAvailable(JNIEnv *, jobject , jlong ptr, jobject)
{
    // a new frame was decoded, let's update our item
    //QMetaObject::invokeMethod(reinterpret_cast<QSurfaceTexture*>(ptr), "update", Qt::QueuedConnection);
}*/

QSurfaceTexture::QSurfaceTexture(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlags(ItemHasContents);
}

QSurfaceTexture::~QSurfaceTexture()
{
    // Delete our texture
    if (m_textureId) {
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);
        glDeleteTextures(1, &m_textureId);
    }
}

void QSurfaceTexture::set_video_texture_size(int width_px, int height_px)
{
    m_texture_width_px=width_px;
    m_texture_height_px=height_px;
}

// No idea how / why this works, but it works.
static void qrectf_flip_horizontally(QRectF& rect){
    float tmp = rect.top();
    rect.setTop(rect.bottom());
    rect.setBottom(tmp);
}

QSGNode *QSurfaceTexture::updatePaintNode(QSGNode *n, QQuickItem::UpdatePaintNodeData *)
{
    SurfaceTextureNode *node = static_cast<SurfaceTextureNode *>(n);
    if (!node) {
        // Create texture
        glGenTextures(1, &m_textureId);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, m_textureId);

        // Can't do mipmapping with camera source
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        // Clamp to edge is the only option
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // Create surface texture Java object
        m_surfaceTexture = QAndroidJniObject("android/graphics/SurfaceTexture", "(I)V", m_textureId);

        // We need to setOnFrameAvailableListener, to be notify when a new frame was decoded
        // and is ready to be displayed. Check android/src/com/kdab/android/SurfaceTextureListener.java
        // file for implementation details.
        /*m_surfaceTexture.callMethod<void>("setOnFrameAvailableListener",
                                          "(Landroid/graphics/SurfaceTexture$OnFrameAvailableListener;)V",
                                          QAndroidJniObject("org/openhd/SurfaceTextureListener",
                                                            "(J)V", jlong(this)).object());*/

        // Create our SurfaceTextureNode
        node = new SurfaceTextureNode(m_surfaceTexture, m_textureId);
        emit surfaceTextureChanged(this);
    }
    QRectF rect(boundingRect());
    if(m_texture_width_px>0 && m_texture_height_px>0){
        auto coords=helper::ratio::calculate_viewport(boundingRect().width(),boundingRect().height(),m_texture_width_px,m_texture_height_px,QOpenHDVideoHelper::get_primary_video_scale_to_fit());
        rect=QRectF(coords.x,coords.y,coords.width,coords.height);
    }
    // flip vertical - for some reason video by default is upside down on android otherwise
    qrectf_flip_horizontally(rect);

     const QRectF texture_coords=QRectF(0, 0, 1, 1);

    //qDebug()<<rect.width()<<" "<<rect.height();
    //rect.setWidth(rect.width()*0.5);

    QSGGeometry::updateTexturedRectGeometry(node->geometry(), rect, texture_coords);
    node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    // XX
    QMetaObject::invokeMethod(reinterpret_cast<QSurfaceTexture*>(this), "update", Qt::QueuedConnection);
    return node;
}

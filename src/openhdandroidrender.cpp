#if defined(ENABLE_VIDEO_RENDER)
#if defined(__android__)

#include "openhdandroidrender.h"

#include <QAndroidJniEnvironment>
#include <QSGGeometryNode>
#include <QSGSimpleMaterialShader>
#include <QQuickWindow>
#include <QApplication>

struct State {
    QMatrix4x4 uSTMatrix;
    GLuint textureId = 0;

    int compare(const State *other) const
    {
        return (uSTMatrix == other->uSTMatrix && textureId == other->textureId) ? 0 : -1;
    }
};


class SurfaceTextureShader : QSGSimpleMaterialShader<State> {
    QSG_DECLARE_SIMPLE_COMPARABLE_SHADER(SurfaceTextureShader, State)
public:
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

    QList<QByteArray> attributes() const override {
        return QList<QByteArray>() << "aPosition" << "aTextureCoord";
    }

    void updateState(const State *state, const State *) override {
        program()->setUniformValue(m_uSTMatrixLoc, state->uSTMatrix);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, state->textureId);
    }

    void resolveUniforms() override {
        m_uSTMatrixLoc = program()->uniformLocation("uSTMatrix");
        program()->setUniformValue("sTexture", 0);
    }

private:
    int m_uSTMatrixLoc;
};

class SurfaceTextureNode : public QSGGeometryNode
{
public:
    SurfaceTextureNode(const QAndroidJniObject &surfaceTexture, GLuint textureId): QSGGeometryNode(),
                                                                                   m_surfaceTexture(surfaceTexture),
                                                                                   m_geometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4),
                                                                                   m_textureId(textureId) {
        setFlag(UsePreprocess);

        setGeometry(&m_geometry);

        QSGSimpleMaterial<State> *material = SurfaceTextureShader::createMaterial();
        material->state()->textureId = m_textureId;
        material->setFlag(QSGMaterial::Blending, false);
        setMaterial(material);
        setFlag(OwnsMaterial);

        QAndroidJniEnvironment env;
        jfloatArray array = env->NewFloatArray(16);
        m_uSTMatrixArray = jfloatArray(env->NewGlobalRef(array));
        env->DeleteLocalRef(array);
    }

    ~SurfaceTextureNode() override {
        QAndroidJniEnvironment()->DeleteGlobalRef(m_uSTMatrixArray);
    }

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
    if (!mat) {
        return;
    }
    m_surfaceTexture.callMethod<void>("updateTexImage");
    m_surfaceTexture.callMethod<void>("getTransformMatrix", "([F)V", m_uSTMatrixArray);
    QAndroidJniEnvironment env;
    env->GetFloatArrayRegion(m_uSTMatrixArray, 0, 16, mat->state()->uSTMatrix.data());
}


extern "C" void Java_com_openhd_android_SurfaceTextureListener_frameAvailable(JNIEnv env, jobject jthis, jlong ptr, jobject surfaceTexture) {
    auto item = reinterpret_cast<OpenHDAndroidRender*>(ptr);
    QMetaObject::invokeMethod(item, "update", Qt::QueuedConnection);
}


OpenHDAndroidRender::OpenHDAndroidRender(QQuickItem *parent): QQuickItem(parent) {
    setFlags(ItemHasContents);
    connect(this, &OpenHDAndroidRender::onUpdate, this, &OpenHDAndroidRender::doUpdate, Qt::QueuedConnection);
    connect(this, &QQuickItem::windowChanged, this, &OpenHDAndroidRender::handleWindowChanged);
}


void OpenHDAndroidRender::setWindow(QQuickWindow *window) {
    m_window = window;
    //m_window->setClearBeforeRendering(false);
    emit windowChanged(m_window);
}

void OpenHDAndroidRender::handleWindowChanged(QQuickWindow *window) {
    if (!window) {
        return;
    }
    m_window = window;
    //connect(m_window, &QQuickWindow::sceneGraphInvalidated, this, &OpenHDAndroidRender::cleanup, Qt::DirectConnection);
    //m_window->setClearBeforeRendering(false);
}

void OpenHDAndroidRender::doUpdate() {
    window()->update();
}

OpenHDAndroidRender::~OpenHDAndroidRender() {
    if (m_textureId) {
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);
        glDeleteTextures(1, &m_textureId);
    }
}


QSGNode *OpenHDAndroidRender::updatePaintNode(QSGNode *n, QQuickItem::UpdatePaintNodeData *) {
    SurfaceTextureNode *node = static_cast<SurfaceTextureNode *>(n);
    if (!node) {
        glGenTextures(1, &m_textureId);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, m_textureId);
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        m_surfaceTexture = QAndroidJniObject("android/graphics/SurfaceTexture", "(I)V", m_textureId);
        m_surfaceTexture.callMethod<void>("setOnFrameAvailableListener",
                                          "(Landroid/graphics/SurfaceTexture$OnFrameAvailableListener;)V",
                                          QAndroidJniObject("com/openhd/android/SurfaceTextureListener",
                                                            "(J)V", jlong(this)).object());
        node = new SurfaceTextureNode(m_surfaceTexture, m_textureId);
        emit surfaceTextureChanged(this);
    }

    QRectF rect(boundingRect());
    float tmp = rect.top();
    rect.setTop(rect.bottom());
    rect.setBottom(tmp);

    QSGGeometry::updateTexturedRectGeometry(node->geometry(), rect, QRectF(0, 0, 1, 1));
    node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    if (m_window) {
        m_window->update();
    }
    //emit onUpdate();
    return node;
}

#endif
#endif

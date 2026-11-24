#pragma once

#if defined(__linux__) && !defined(__android__) && defined(QOPENHD_DESKTOP_HW_DECODE)
#define QOPENHD_X86_KMS_AVAILABLE
struct AVFrame;
class QQuickWindow;

namespace X86Kms {
// Explicitly enabled by the appliance launcher, before QApplication exists.
bool prepare();
void attach(QQuickWindow* window);
// Retains the decoder surface until scanout has moved to the next framebuffer.
bool enqueue(AVFrame* frame);
void disable();
}
#endif

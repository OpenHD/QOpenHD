#include "GroundOsdRecorder.hpp"
#include "../nxp/DecodedFrame.hpp"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QPainter>
#include <QQuickItem>
#include <QQuickWindow>
#include <QSocketNotifier>
#include <QStorageInfo>
#include <QUuid>

#include <rk_mpi.h>
#include <mpp_buffer.h>
#include <rk_venc_cfg.h>
#include <mpp_meta.h>
extern "C" {
#include <libavformat/avformat.h>
#include <libavutil/mem.h>
#include <libswscale/swscale.h>
}

#include <algorithm>
#include <chrono>
#include <cerrno>
#include <csignal>
#include <cstring>
#include <stdexcept>
#include <fcntl.h>
#include <linux/dma-buf.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <unistd.h>

namespace {
constexpr int fps = 30;
constexpr qint64 maxFileBytes = 3900LL * 1024 * 1024;
constexpr uint64_t reserveBytes = 64ULL * 1024 * 1024;

volatile sig_atomic_t shutdownWriteFd = -1;
struct sigaction previousSigterm {};

void notifyShutdown(int) {
    const int savedErrno = errno;
    const char byte = 0;
    if (shutdownWriteFd >= 0) {
        const auto written = ::write(shutdownWriteFd, &byte, 1);
        (void)written;
    }
    errno = savedErrno;
}

void require(bool ok, const char* error) {
    if (!ok) throw std::runtime_error(error);
}

qint64 nowMs() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

bool hasSpace(int directoryFd) {
    struct statvfs info {};
    return fstatvfs(directoryFd, &info) == 0 &&
        uint64_t(info.f_bavail) * info.f_frsize >= reserveBytes;
}

struct ScopedFd {
    int value;
    ~ScopedFd() { if (value >= 0) close(value); }
};

bool syncDma(int fd, uint64_t flags) {
    struct dma_buf_sync sync { flags };
    int result;
    do { result = ioctl(fd, DMA_BUF_IOCTL_SYNC, &sync); } while (result < 0 && errno == EINTR);
    return result == 0;
}

class MappedVideo {
public:
    explicit MappedVideo(const nxp::DecodedFrame& video)
        : fd_(video.dmaFd()), size_(video.uvOffset + video.uvStride * ((video.paddedHeight + 1) / 2)) {
        data_ = mmap(nullptr, size_, PROT_READ, MAP_SHARED, fd_, 0);
        require(data_ != MAP_FAILED, "Cannot map the decoded video buffer");
        if (!syncDma(fd_, DMA_BUF_SYNC_START | DMA_BUF_SYNC_READ)) {
            munmap(data_, size_);
            throw std::runtime_error("Cannot synchronize the decoded video buffer");
        }
    }
    ~MappedVideo() {
        syncDma(fd_, DMA_BUF_SYNC_END | DMA_BUF_SYNC_READ);
        munmap(data_, size_);
    }
    const uint8_t* data() const { return static_cast<const uint8_t*>(data_); }
private:
    int fd_;
    size_t size_;
    void* data_;
};

struct Frame {
    MppFrame value = nullptr;
    ~Frame() { if (value) mpp_frame_deinit(&value); }
};

struct Packet {
    MppPacket value = nullptr;
    ~Packet() { if (value) mpp_packet_deinit(&value); }
};

class Recording {
public:
    ~Recording() {
        if (mux_) {
            avio_closep(&mux_->pb);
            avformat_free_context(mux_);
        }
        if (ctx_) mpp_destroy(ctx_);
        if (config_) mpp_enc_cfg_deinit(config_);
        if (buffer_) mpp_buffer_put(buffer_);
        if (group_) mpp_buffer_group_put(group_);
        sws_freeContext(fromVideo_);
        sws_freeContext(toEncoder_);
        if (!wroteFrame_ && !partial_.isEmpty()) unlinkat(directoryFd_, partial_.constData(), 0);
    }

    void open(int directoryFd, QSize size) {
        directoryFd_ = directoryFd;
        size_ = size;
        stride_ = (size.width() + 15) & ~15;
        rows_ = (size.height() + 15) & ~15;
        require(mpp_create(&ctx_, &api_) == MPP_OK &&
                mpp_init(ctx_, MPP_CTX_ENC, MPP_VIDEO_CodingAVC) == MPP_OK &&
                mpp_enc_cfg_init(&config_) == MPP_OK &&
                api_->control(ctx_, MPP_ENC_GET_CFG, config_) == MPP_OK,
                "Rockchip H.264 encoder could not be initialized");
        RK_S64 timeout = 250;
        require(api_->control(ctx_, MPP_SET_INPUT_TIMEOUT, &timeout) == MPP_OK &&
                api_->control(ctx_, MPP_SET_OUTPUT_TIMEOUT, &timeout) == MPP_OK,
                "Rockchip encoder rejected bounded timeouts");
        const std::pair<const char*, int> settings[] = {
            {"codec:type", MPP_VIDEO_CodingAVC},
            {"prep:width", size.width()}, {"prep:height", size.height()},
            {"prep:hor_stride", stride_}, {"prep:ver_stride", rows_},
            {"prep:format", MPP_FMT_YUV420SP}, {"prep:range", MPP_FRAME_RANGE_MPEG},
            {"prep:colorspace", MPP_FRAME_SPC_BT709},
            {"rc:mode", MPP_ENC_RC_MODE_CBR},
            {"rc:fps_in_flex", 1}, {"rc:fps_in_num", fps}, {"rc:fps_in_denom", 1},
            {"rc:fps_out_flex", 1}, {"rc:fps_out_num", fps}, {"rc:fps_out_denom", 1},
            {"rc:bps_target", 6000000}, {"rc:bps_min", 5500000}, {"rc:bps_max", 6500000},
            {"rc:gop", 30}, {"h264:profile", 100}, {"h264:level", 32}, {"h264:cabac_en", 1}
        };
        for (const auto& setting : settings) {
            if (mpp_enc_cfg_set_s32(config_, setting.first, setting.second) != MPP_OK)
                throw std::runtime_error(std::string("Rockchip encoder rejected ") + setting.first);
        }
        require(api_->control(ctx_, MPP_ENC_SET_CFG, config_) == MPP_OK,
                "Rockchip encoder configuration failed");
        require(mpp_buffer_group_get_internal(&group_, static_cast<MppBufferType>(
                    MPP_BUFFER_TYPE_DRM | MPP_BUFFER_FLAGS_CACHABLE)) == MPP_OK &&
                mpp_buffer_get(group_, &buffer_, stride_ * rows_ * 3 / 2) == MPP_OK,
                "Cannot allocate Rockchip encoder input");

        MppBuffer headerBuffer = nullptr;
        require(mpp_buffer_get(group_, &headerBuffer, 4096) == MPP_OK, "Cannot allocate H.264 header");
        Packet header;
        const auto result = mpp_packet_init_with_buffer(&header.value, headerBuffer);
        mpp_buffer_put(headerBuffer);
        require(result == MPP_OK, "Cannot initialize H.264 header");
        mpp_packet_set_length(header.value, 0);
        require(api_->control(ctx_, MPP_ENC_GET_HDR_SYNC, header.value) == MPP_OK,
                "Cannot read H.264 codec header");
        const auto length = mpp_packet_get_length(header.value);
        require(length > 0 && length <= 4096 && mpp_packet_get_pos(header.value),
                "Invalid H.264 codec header");

        require(avformat_alloc_output_context2(&mux_, nullptr, "matroska", nullptr) >= 0,
                "Cannot initialize Matroska output");
        stream_ = avformat_new_stream(mux_, nullptr);
        require(stream_, "Cannot create Matroska video track");
        stream_->time_base = {1, 1000};
        stream_->avg_frame_rate = {fps, 1};
        auto* codec = stream_->codecpar;
        codec->codec_type = AVMEDIA_TYPE_VIDEO;
        codec->codec_id = AV_CODEC_ID_H264;
        codec->width = size.width();
        codec->height = size.height();
        codec->color_space = AVCOL_SPC_BT709;
        codec->color_range = AVCOL_RANGE_MPEG;
        codec->extradata = static_cast<uint8_t*>(av_mallocz(length + AV_INPUT_BUFFER_PADDING_SIZE));
        require(codec->extradata, "Cannot allocate Matroska codec header");
        std::memcpy(codec->extradata, mpp_packet_get_pos(header.value), length);
        codec->extradata_size = int(length);

        name_ = QStringLiteral("ground-osd_%1_%2.mkv")
            .arg(QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd_HH-mm-ss")),
                 QUuid::createUuid().toString(QUuid::WithoutBraces).left(8));
        const auto final = QFile::encodeName(name_);
        partial_ = "." + final + ".part";
        const auto path = "/proc/self/fd/" + QByteArray::number(directoryFd_) + '/' + partial_;
        require(avio_open(&mux_->pb, path.constData(), AVIO_FLAG_WRITE) >= 0 &&
                avformat_write_header(mux_, nullptr) >= 0, "Cannot open recording on /Video");
    }

    QString name() const { return name_; }

    void write(const nxp::DecodedFrame& video, const QImage& hud, qint64 timestamp,
               bool stretch, int rotation) {
        int width = int(video.width);
        int height = int(video.height);
        const bool quarterTurn = rotation == 90 || rotation == 270;
        const QSize oriented = quarterTurn ? QSize(height, width) : QSize(width, height);
        const QSize target = stretch ? size_ : oriented.scaled(size_, Qt::KeepAspectRatio);
        QImage picture(quarterTurn ? target.transposed() : target, QImage::Format_RGB32);
        require(!picture.isNull(), "Cannot allocate a recording frame");

        fromVideo_ = sws_getCachedContext(fromVideo_, width, height, AV_PIX_FMT_NV12,
            picture.width(), picture.height(), AV_PIX_FMT_BGRA, SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);
        require(fromVideo_, "Cannot scale the decoded video");
        const auto* inputColor = sws_getCoefficients(height > 576 ? SWS_CS_ITU709 : SWS_CS_ITU601);
        const auto* outputColor = sws_getCoefficients(SWS_CS_ITU709);
        require(sws_setColorspaceDetails(fromVideo_, inputColor, 0, outputColor, 1,
                    0, 1 << 16, 1 << 16) >= 0, "Cannot configure video color conversion");
        {
            MappedVideo mapping(video);
            const uint8_t* src[] = {
                mapping.data() + video.yOffset + video.cropTop * video.yStride + video.cropLeft,
                mapping.data() + video.uvOffset + (video.cropTop / 2) * video.uvStride + (video.cropLeft & ~size_t(1)),
                nullptr, nullptr
            };
            const int strides[] = {int(video.yStride), int(video.uvStride), 0, 0};
            uint8_t* dst[] = {picture.bits(), nullptr, nullptr, nullptr};
            const int dstStrides[] = {picture.bytesPerLine(), 0, 0, 0};
            require(sws_scale(fromVideo_, src, strides, 0, height, dst, dstStrides) == picture.height(),
                    "Decoded video conversion failed");
        }

        QImage canvas(size_, QImage::Format_RGB32);
        require(!canvas.isNull(), "Cannot allocate the recording canvas");
        canvas.fill(Qt::black);
        {
            QPainter painter(&canvas);
            painter.save();
            painter.translate((size_.width() - target.width()) / 2 + target.width() / 2.0,
                              (size_.height() - target.height()) / 2 + target.height() / 2.0);
            painter.rotate(-rotation); // Wayland buffer transforms are counter-clockwise.
            painter.drawImage(QPointF(-picture.width() / 2.0, -picture.height() / 2.0), picture);
            painter.restore();
            painter.drawImage(canvas.rect(), hud);
        }

        toEncoder_ = sws_getCachedContext(toEncoder_, size_.width(), size_.height(), AV_PIX_FMT_BGRA,
            size_.width(), size_.height(), AV_PIX_FMT_NV12, SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);
        require(toEncoder_ && sws_setColorspaceDetails(toEncoder_, outputColor, 1, outputColor, 0,
                    0, 1 << 16, 1 << 16) >= 0, "Cannot configure encoder color conversion");
        auto* pixels = static_cast<uint8_t*>(mpp_buffer_get_ptr(buffer_));
        require(pixels && mpp_buffer_sync_begin(buffer_) == MPP_OK, "Cannot map encoder input");
        auto* uv = pixels + stride_ * rows_;
        uint8_t* dst[] = {pixels, uv, nullptr, nullptr};
        const int dstStrides[] = {stride_, stride_, 0, 0};
        const uint8_t* src[] = {canvas.constBits(), nullptr, nullptr, nullptr};
        const int srcStrides[] = {canvas.bytesPerLine(), 0, 0, 0};
        const int converted = sws_scale(toEncoder_, src, srcStrides, 0, size_.height(), dst, dstStrides);
        require(mpp_buffer_sync_end(buffer_) == MPP_OK && converted == size_.height(),
                "Encoder input conversion failed");

        if (firstPts_ < 0) firstPts_ = timestamp;
        Frame frame;
        require(mpp_frame_init(&frame.value) == MPP_OK, "Cannot allocate the MPP video frame");
        mpp_frame_set_width(frame.value, size_.width());
        mpp_frame_set_height(frame.value, size_.height());
        mpp_frame_set_hor_stride(frame.value, stride_);
        mpp_frame_set_ver_stride(frame.value, rows_);
        mpp_frame_set_fmt(frame.value, MPP_FMT_YUV420SP);
        mpp_frame_set_buffer(frame.value, buffer_);
        mpp_frame_set_pts(frame.value, timestamp - firstPts_);
        require(api_->encode_put_frame(ctx_, frame.value) == MPP_OK, "Rockchip encoder input timed out");
        Packet encoded;
        require(api_->encode_get_packet(ctx_, &encoded.value) == MPP_OK && encoded.value,
                "Rockchip encoder output timed out");
        require(!mpp_packet_is_partition(encoded.value), "Unexpected split H.264 encoder output");
        const auto length = mpp_packet_get_length(encoded.value);
        if (!length) return;

        AVPacket packet {};
        packet.stream_index = stream_->index;
        packet.data = static_cast<uint8_t*>(mpp_packet_get_pos(encoded.value));
        packet.size = int(length);
        packet.pts = packet.dts = av_rescale_q(mpp_packet_get_pts(encoded.value), AVRational{1, 1000}, stream_->time_base);
        packet.duration = av_rescale_q(1, AVRational{1, fps}, stream_->time_base);
        RK_S32 intra = 0;
        if (auto meta = mpp_packet_get_meta(encoded.value)) mpp_meta_get_s32(meta, KEY_OUTPUT_INTRA, &intra);
        if (intra || !wroteFrame_) packet.flags = AV_PKT_FLAG_KEY;
        require(av_write_frame(mux_, &packet) >= 0 && mux_->pb->error >= 0,
                "Writing the recording failed");
        wroteFrame_ = true;
    }

    bool hasFrames() const { return wroteFrame_; }
    bool reachedLimit() const { return avio_tell(mux_->pb) >= maxFileBytes; }

    void finish() {
        const auto trailer = av_write_trailer(mux_);
        const auto error = mux_->pb->error;
        const auto closed = avio_closep(&mux_->pb);
        require(trailer >= 0 && error >= 0 && closed >= 0, "Cannot finalize the recording");
        const ScopedFd file{openat(directoryFd_, partial_.constData(), O_RDONLY | O_CLOEXEC)};
        require(file.value >= 0 && fsync(file.value) == 0, "Cannot flush the recording to storage");
        const auto final = QFile::encodeName(name_);
        require(renameat(directoryFd_, partial_.constData(), directoryFd_, final.constData()) == 0,
                "Cannot publish the recording file");
    }

private:
    MppCtx ctx_ = nullptr;
    MppApi* api_ = nullptr;
    MppEncCfg config_ = nullptr;
    MppBufferGroup group_ = nullptr;
    MppBuffer buffer_ = nullptr;
    AVFormatContext* mux_ = nullptr;
    AVStream* stream_ = nullptr;
    SwsContext* fromVideo_ = nullptr;
    SwsContext* toEncoder_ = nullptr;
    QString name_;
    QByteArray partial_;
    int directoryFd_ = -1;
    QSize size_;
    int stride_ = 0, rows_ = 0;
    qint64 firstPts_ = -1;
    bool wroteFrame_ = false;
};
}

GroundOsdRecorder::GroundOsdRecorder() {
    timer_.setTimerType(Qt::PreciseTimer);
    timer_.setInterval(1000 / fps);
    connect(&timer_, &QTimer::timeout, this, &GroundOsdRecorder::capture);
}

GroundOsdRecorder::~GroundOsdRecorder() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        collecting_ = false;
    }
    ready_.notify_one();
    if (worker_.joinable()) worker_.join();
    if (shutdownNotifier_) {
        sigaction(SIGTERM, &previousSigterm, nullptr);
        const int writeFd = shutdownWriteFd;
        shutdownWriteFd = -1;
        delete shutdownNotifier_;
        close(shutdownReadFd_);
        close(writeFd);
    }
}

bool GroundOsdRecorder::available() const {
    if (qEnvironmentVariableIntValue("QOPENHD_ZERO3W_OSD_RECORDING") == 1) return true;
    QFile compatible(QStringLiteral("/proc/device-tree/compatible"));
    if (!compatible.open(QIODevice::ReadOnly)) return false;
    for (const auto& board : compatible.readAll().split('\0')) {
        if (board.startsWith("radxa,zero3w")) return true;
    }
    return false;
}

void GroundOsdRecorder::setWindow(QQuickWindow* window) {
    window_ = window;
    if (!available() || shutdownNotifier_) return;
    // systemd stops QOpenHD with SIGTERM. Let the Qt shutdown path join the
    // writer and close the Matroska file before exiting.
    int pipe[2];
    if (pipe2(pipe, O_NONBLOCK | O_CLOEXEC) != 0) {
        qWarning() << "Could not create Ground recorder shutdown pipe";
        return;
    }
    shutdownWriteFd = pipe[1];
    struct sigaction action {};
    action.sa_handler = notifyShutdown;
    sigemptyset(&action.sa_mask);
    if (sigaction(SIGTERM, &action, &previousSigterm) != 0) {
        shutdownWriteFd = -1;
        close(pipe[0]);
        close(pipe[1]);
        qWarning() << "Could not install Ground recorder shutdown handler";
        return;
    }
    shutdownReadFd_ = pipe[0];
    shutdownNotifier_ = new QSocketNotifier(shutdownReadFd_, QSocketNotifier::Read, this);
    connect(shutdownNotifier_, &QSocketNotifier::activated, this, [this] {
        shutdownNotifier_->setEnabled(false);
        stop();
        QCoreApplication::quit();
    });
}

void GroundOsdRecorder::submitVideo(std::shared_ptr<nxp::DecodedFrame> frame) {
    if (!collecting_) return;
    std::lock_guard<std::mutex> lock(mutex_);
    if (!collecting_) return;
    video_ = std::move(frame);
    videoTime_ = nowMs();
}

void GroundOsdRecorder::setVideoLayout(bool stretch, int rotation) {
    stretch_ = stretch;
    rotation_ = rotation;
}

void GroundOsdRecorder::clearVideo() {
    std::lock_guard<std::mutex> lock(mutex_);
    video_.reset();
}

void GroundOsdRecorder::start() {
    if (!available() || active_ || stopping_ || !window_ || !window_->isExposed()) return;
    const QStorageInfo storage(QStringLiteral("/Video"));
    ScopedFd directory{::open("/Video", O_RDONLY | O_DIRECTORY | O_CLOEXEC)};
    struct stat root {}, target {};
    if (storage.rootPath() != QFileInfo(QStringLiteral("/Video")).canonicalFilePath() ||
        storage.isReadOnly() ||
        directory.value < 0 || stat("/", &root) != 0 || fstat(directory.value, &target) != 0 ||
        root.st_dev == target.st_dev || !hasSpace(directory.value)) {
        status_ = tr("Mount a writable recordings partition at /Video with at least 64 MiB free.");
        emit stateChanged();
        return;
    }

    size_ = window_->size();
    if (size_.width() > 1280 || size_.height() > 720)
        size_ = size_.scaled(1280, 720, Qt::KeepAspectRatio);
    size_ = QSize(size_.width() & ~1, size_.height() & ~1);
    if (size_.width() < 64 || size_.height() < 64) return;
    elapsed_.start();
    captureFailed_ = false;
    collecting_ = true;
    const int fd = directory.value;
    try {
        worker_ = std::thread([this, fd] { run(fd); });
    } catch (const std::system_error& error) {
        collecting_ = false;
        status_ = tr("Cannot start the recording worker.");
        qWarning() << status_ << error.what();
        emit stateChanged();
        return;
    }
    directory.value = -1;
    active_ = true;
    status_ = tr("Waiting for video");
    timer_.start();
    emit stateChanged();
}

void GroundOsdRecorder::stop() {
    if (!active_ || stopping_) return;
    timer_.stop();
    grab_.reset();
    {
        std::lock_guard<std::mutex> lock(mutex_);
        collecting_ = false;
        video_.reset();
        job_.reset();
    }
    ready_.notify_one();
    stopping_ = true;
    status_ = tr("Saving recordingâ€¦");
    emit stateChanged();
}

void GroundOsdRecorder::capture() {
    if (!collecting_ || !window_ || !window_->isExposed() || grab_) return;
    std::shared_ptr<nxp::DecodedFrame> video;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (busy_ || job_ || !video_ || nowMs() - videoTime_ > 1000) return;
        video = video_;
    }
    auto grab = window_->contentItem()->grabToImage(size_);
    if (!grab) return;
    grab_ = grab;
    connect(grab.data(), &QQuickItemGrabResult::ready, this,
        [this, capture = grab.data(), video = std::move(video), pts = elapsed_.elapsed(),
         stretch = stretch_, rotation = rotation_] {
            if (grab_.data() != capture) return;
            const auto grab = std::move(grab_);
            if (!grab || !collecting_) return;
            if (grab->image().isNull()) {
                captureFailed_ = true;
                stop();
                return;
            }
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (!collecting_) return;
                job_ = std::make_unique<Job>(Job{video, grab->image(), pts, stretch, rotation});
            }
            ready_.notify_one();
        });
}

void GroundOsdRecorder::run(int directoryFd) {
    const ScopedFd directory{directoryFd};
    QString result = tr("No video was recorded.");
    QString failure;
    {
        Recording recording;
        bool opened = false;
        qint64 nextSpaceCheck = 0;
        try {
            for (;;) {
                std::unique_ptr<Job> job;
                {
                    std::unique_lock<std::mutex> lock(mutex_);
                    ready_.wait(lock, [this] { return !collecting_ || job_; });
                    if (!collecting_) break;
                    job = std::move(job_);
                    busy_ = true;
                }
                if (job->pts >= nextSpaceCheck) {
                    require(hasSpace(directoryFd), "The recordings partition is low on space");
                    nextSpaceCheck = job->pts + 1000;
                }
                if (!opened) {
                    recording.open(directoryFd, job->hud.size());
                    opened = true;
                }
                const bool firstFrame = !recording.hasFrames();
                recording.write(*job->video, job->hud, job->pts, job->stretch, job->rotation);
                if (firstFrame && recording.hasFrames()) {
                    QMetaObject::invokeMethod(this, [this] {
                        if (!stopping_) {
                            status_ = tr("Recording video with OSD");
                            emit stateChanged();
                        }
                    }, Qt::QueuedConnection);
                }
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    busy_ = false;
                }
                if (recording.reachedLimit()) {
                    failure = tr("FAT32 file size limit reached.");
                    break;
                }
            }
        } catch (const std::exception& error) {
            failure = QString::fromUtf8(error.what());
        }
        {
            std::lock_guard<std::mutex> lock(mutex_);
            collecting_ = false;
            busy_ = false;
            video_.reset();
            job_.reset();
        }
        if (recording.hasFrames()) {
            try {
                recording.finish();
                result = tr("Saved %1").arg(recording.name());
            } catch (const std::exception& error) {
                result = tr("%1. Partial file kept in /Video.").arg(QString::fromUtf8(error.what()));
            }
        }
    }
    if (!failure.isEmpty()) result = failure + QStringLiteral(" ") + result;
    QMetaObject::invokeMethod(this, [this, result] {
        worker_.join();
        timer_.stop();
        grab_.reset();
        active_ = stopping_ = false;
        status_ = captureFailed_ ? tr("Could not capture the HUD. %1").arg(result) : result;
        qInfo() << "Ground OSD recorder:" << status_;
        emit stateChanged();
    }, Qt::QueuedConnection);
}

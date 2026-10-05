#include <QCoreApplication>
#include <QSslSocket>
#include <cstdio>

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    const bool available = QSslSocket::supportsSsl();
    std::printf("Packaged TLS: available=%d runtime=%s\n", available,
                qPrintable(QSslSocket::sslLibraryVersionString()));
    return available ? 0 : 1;
}

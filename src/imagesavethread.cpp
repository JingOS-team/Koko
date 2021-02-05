#include "imagesavethread.h"

ImageSaveThread::ImageSaveThread(QImage &source,QString &location)
    :QObject()
    ,m_location(location)
    ,m_source(source)
{
}

void ImageSaveThread::run()
{
    if (!m_source.isNull()) {
        m_source.save(m_location);
    }
    emit finished();
}

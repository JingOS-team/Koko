/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Zhang He Gang <zhanghegang@jingos.com>
 *
 */

#ifndef IMAGESAVETHREAD_H
#define IMAGESAVETHREAD_H
#include <QImage>
#include <QObject>
#include <QRunnable>

class ImageSaveThread : public QObject, public QRunnable
{
    Q_OBJECT
public:
    ImageSaveThread(QImage &source,QString &location);
    void run() override;
signals:
    void finished();
private:
    QString m_location;
    QImage &m_source;
};

#endif // IMAGESAVETHREAD_H

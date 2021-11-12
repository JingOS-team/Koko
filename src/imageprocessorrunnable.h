/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2021 Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef KOKO_IMAGEPROCESSORRUNNABLE_H
#define KOKO_IMAGEPROCESSORRUNNABLE_H

#include <QObject>
#include <QRunnable>
#include "types.h"

namespace JingGallery
{
class ReverseGeoCoder;

class ImageProcessorRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    enum ProcessType{
        Process_Default = 0,
        Process_Update = 1
    };
    ImageProcessorRunnable(QString &filePath, Types::MimeType type, ReverseGeoCoder *coder);
    ImageProcessorRunnable(const QString &filePath, Types::MimeType type, ProcessType processType);

    void run() override;

signals:
    void finished();

private:
    QString m_path;
    Types::MimeType m_type;
    ReverseGeoCoder *m_geoCoder;
    ProcessType m_processType;
};
}

#endif // KOKO_IMAGEPROCESSORRUNNABLE_H

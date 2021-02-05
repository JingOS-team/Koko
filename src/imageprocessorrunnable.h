/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
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
    ImageProcessorRunnable(QString &filePath, Types::MimeType type, ReverseGeoCoder *coder);
    void run() override;

signals:
    void finished();

private:
    QString m_path;
    Types::MimeType m_type;
    ReverseGeoCoder *m_geoCoder;
};
}

#endif // KOKO_IMAGEPROCESSORRUNNABLE_H

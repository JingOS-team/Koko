/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *                             Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imageprocessorrunnable.h"
#include <QFileInfo>
#include <QMimeDatabase>
#include <QDebug>
#include <QUrl>
#include "exiv2extractor.h"
#include "mediastorage.h"
#include "reversegeocoder.h"
#define UNICODE
#include <MediaInfo/MediaInfo.h>

using namespace JingGallery;

ImageProcessorRunnable::ImageProcessorRunnable(QString &filePath, Types::MimeType type, ReverseGeoCoder *geoCoder)
    : QObject()
    , m_path(filePath)
    , m_type(type)
    , m_geoCoder(geoCoder)
{
}

ImageProcessorRunnable::ImageProcessorRunnable(const QString &filePath, Types::MimeType type, ProcessType processType)
    : QObject()
    , m_path(filePath)
    , m_type(type)
    , m_processType(processType)
{
}
void ImageProcessorRunnable::run()
{
    MediaInfo ii;
    ii.path = m_path;
    ii.mimeType = m_type;

    if (ii.mimeType == Types::MimeType::Image) {
        Exiv2Extractor extractor;
        extractor.extract(m_path);
        if (extractor.error()) {
            emit finished();
            return;
        }

        ii.dateTime = extractor.dateTime();
        if (ii.dateTime.isNull()) {
            ii.dateTime = QFileInfo(m_path).birthTime();
        }
        if (ii.dateTime.isNull()) {
            ii.dateTime = QFileInfo(m_path).lastModified();
        }
        ii.duration = -1;
    } else {
        MediaInfoLib::MediaInfo MI;
        if (MI.Open(m_path.toStdWString())) {
            QString durationStr = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_General, 0, __T("Duration")));
            QString rotationStr = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Rotation")));
            ii.duration = (QString::fromStdWString(MI.Get(MediaInfoLib::Stream_General, 0, __T("Duration"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt()) / 1000;
            ii.width = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Width"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            ii.width = ii.width > 0 ? ii.width : 800;
            ii.height = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Height"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            ii.height = ii.height > 0 ? ii.height : 600;
            int svDuration = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Duration"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt() / 1000;
            if(ii.duration <= 0 && svDuration > 0){
                ii.duration = svDuration;
            }
            ii.rotation = rotationStr.toDouble();
        } else {
            ii.duration = 0;
            ii.width = 800;
            ii.height = 600;
        }

        MI.Close();
        ii.dateTime = QFileInfo(m_path).birthTime();
        if (ii.dateTime.isNull()) {
            ii.dateTime = QFileInfo(m_path).lastModified();
        }
    }
    if (m_processType == Process_Update) {
        if (ii.duration > 0) {
            QMetaObject::invokeMethod(MediaStorage::instance(), "updateMedia", Qt::AutoConnection, Q_ARG(const MediaInfo &, ii));
            emit finished();
        }
    } else {
        QMetaObject::invokeMethod(MediaStorage::instance(), "addMedia", Qt::AutoConnection, Q_ARG(const MediaInfo &, ii));
        emit finished();
    }
}

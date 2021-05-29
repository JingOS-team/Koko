/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 *             2021 Wang Rui <wangrui@jingos.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "imagedocument.h"
#include <QMatrix>
#include <QUrl>
#include <QDebug>
#include <QFileInfo>
#include <QDateTime>
#include "exiv2extractor.h"
#include "listimageprovider.h"
#include "medialistmodel.h"
#include <QThread>
#include "imagesavethread.h"
#include <QThreadPool>
#include <QImageReader>

ImageDocument::ImageDocument()
{
    connect(this, &ImageDocument::pathChanged,
    this, [this] (const QString &url) {
        Q_EMIT resetHandle();
        /** Since the url passed by the model in the ImageViewer.qml contains 'file://' prefix */
        const QString location = QUrl(url).path();
        QImageReader imageRead(location);
        imageRead.setAutoTransform(true);
        m_undoImages.append(imageRead.read());
        m_edited = false;
        Q_EMIT editedChanged();
        Q_EMIT visualImageChanged();
    });
}

ImageDocument::~ImageDocument()
{
    m_undoImages.clear();
}

QString ImageDocument::path() const
{
    return m_path;
}

void ImageDocument::setPath(const QString& url)
{
    m_path = url;
    emit pathChanged(url);
}

QImage ImageDocument::visualImage() const
{
    if (m_undoImages.isEmpty()) {
        return {};
    }
    return m_undoImages.last();
}

bool ImageDocument::clearUndoImage()
{
    if (m_undoImages.isEmpty()) {
        return {};
    }
    while (m_undoImages.count() > 1) {
        m_undoImages.pop_back();
    }
    emit visualImageChanged();
    return true;
}

bool ImageDocument::edited() const
{
    return m_edited;
}

void ImageDocument::setEdited(bool value)
{
    m_edited = value;
    emit editedChanged();
}

void ImageDocument::rotate(int angle)
{
    QTransform tranform;
    tranform.rotate(angle);
    setEdited(true);
    m_undoImages.append(m_undoImages.last().transformed(tranform,  Qt::FastTransformation));
    Q_EMIT visualImageChanged();
}

void ImageDocument::mirror(bool horizontal, bool vertical)
{
    setEdited(true);
    m_undoImages.append(m_undoImages.last().mirrored(horizontal, vertical));
    Q_EMIT visualImageChanged();
}


void ImageDocument::crop(int x, int y, int width, int height)
{
    if (x < 0) {
        width += x;
        x = 0;
    }
    if (y < 0) {
        height += y;
        y = 0;
    }
    if (m_undoImages.last().width() < width + x) {
        width = m_undoImages.last().width() - x;
    }
    if (m_undoImages.last().height() < height + y) {
        height = m_undoImages.last().height() - y;
    }

    const QRect rect(x, y, width, height);
    setEdited(true);
    m_undoImages.append(m_undoImages.last().copy(rect));
    Q_EMIT visualImageChanged();
}

bool ImageDocument::save()
{
    QString location = QUrl(m_path).path();

    QFileInfo lt(location);
    if (!lt.isWritable()) {
        return false;
    }

    ImageSaveThread *saveThread = new ImageSaveThread(m_undoImages.last(),location);
    connect(saveThread, SIGNAL(finished()), this, SLOT(slotFinished()));
    QThreadPool::globalInstance()->start(saveThread);
    return true;
}

void ImageDocument::slotFinished()
{

    while (m_undoImages.count() > 1) {
        m_undoImages.pop_front();
    }
    Q_EMIT resetHandle();
    Q_EMIT updateThumbnail();
    setEdited(false);
    Q_EMIT visualImageChanged();
}

bool ImageDocument::saveAs()
{
    QString location = QUrl(m_path).path();

    QFileInfo lt(location);
    if (!lt.isWritable()) {
        return false;
    }
    QStringList sqlits = lt.fileName().split(".");
    QString locationPath = lt.path();
    QString suffix = sqlits.size() > 0 ? "."+sqlits.last() : "";
    QString newFileName =  lt.fileName().replace(suffix,"");
    QString newFilePath = locationPath+"/"+newFileName+"_copy";

    int cur = 1;
    QString updatedPath = newFilePath + suffix;
    QFileInfo check(newFilePath + suffix);
    while (check.exists()) {
        updatedPath = QString("%1_%2%3").arg(newFilePath, QString::number(cur), suffix);
        check = QFileInfo(updatedPath);
        cur++;
    }

    QImage lastImage =  m_undoImages.last();
    bool isSaveSuc = lastImage.save(updatedPath);
    QImage scaledImage = lastImage.scaled(256,256,Qt::KeepAspectRatio,Qt::SmoothTransformation);
    MediaStorage::instance()->m_imageCache->insertImage("file://" + updatedPath,scaledImage);

    Exiv2Extractor extractor;
    extractor.setFileDateTime(location,updatedPath);

    MediaStorage::instance()->addImage(updatedPath);
    Q_EMIT resetHandle();
    setEdited(false);
    setPath(updatedPath);
    Q_EMIT visualImageChanged();
    return true;
}

void ImageDocument::undo()
{
    Q_ASSERT(m_undoImages.count() > 1);
    m_undoImages.pop_back();

    if (m_undoImages.count() == 1) {
        setEdited(false);
    }

    Q_EMIT visualImageChanged();
}

void ImageDocument::cancel()
{
    while (m_undoImages.count() > 1) {
        m_undoImages.pop_back();
    }
    Q_EMIT resetHandle();
    m_edited = false;
    Q_EMIT editedChanged();
}


#include "moc_imagedocument.cpp"

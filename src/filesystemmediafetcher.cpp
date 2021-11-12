/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "filesystemmediafetcher.h"

#include <QDirIterator>
#include <QMimeDatabase>
#include <QTimer>

FileSystemMediaFetcher::FileSystemMediaFetcher(const QString &folder, QObject *parent)
    : QObject(parent)
    , m_folder(folder)
{
}

void FileSystemMediaFetcher::fetch()
{
    QTimer::singleShot(0, this, SLOT(slotProcess()));
}

void FileSystemMediaFetcher::slotProcess()
{
    QMimeDatabase mimeDb;

    QDirIterator it(m_folder, QDir::AllEntries | QDir::NoSymLinks | QDir::NoDotAndDotDot , QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString filePath = it.next();
        QString mimetype = mimeDb.mimeTypeForFile(filePath).name();
        if (mimetype.startsWith("image/"))
            Q_EMIT mediaResult(filePath, Types::MimeType::Image);
        else if (mimetype.startsWith("video/"))
            Q_EMIT mediaResult(filePath, Types::MimeType::Video);
    }

    Q_EMIT finished();
}

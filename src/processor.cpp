/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: (C) 2021  Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "processor.h"
#include "imageprocessorrunnable.h"
#include "mediastorage.h"

#include <QDebug>
#include <QEventLoop>
#include <QFileInfo>
#include <QThreadPool>

using namespace JingGallery;

Processor::Processor(QObject *parent)
    : QObject(parent)
    , m_numFiles(0)
    , m_processing(false)
    , m_initialScanDone(false)
{
    connect(&m_commitTimer, &CommitTimer::timeout, [&]() {
        MediaStorage::instance()->commit();
        if (m_files.isEmpty()) {
            m_geoCoder.deinit();
            if (m_numFiles == 0 && m_initialScanDone){
                m_isFinished = true;
                emit finishedChanged();
            }
        }
    });

    connect(this, &Processor::numFilesChanged, &m_commitTimer, &CommitTimer::start);
}

Processor::~Processor()
{
}

void Processor::addFile(const QString &filePath, Types::MimeType type)
{
    m_files << qMakePair(type, filePath);
    m_numFiles++;

    QTimer::singleShot(0, this, SLOT(process()));
    emit numFilesChanged();
}

void Processor::removeFile(const QList<QString> &filePaths)
{
    MediaStorage::instance()->removeMedia(filePaths);

    emit numFilesChanged();
}

void Processor::updateFile(const QString &filePath, Types::MimeType type)
{
    QString updateFilePath = filePath;
    if (updateFilePath.startsWith("file://")) {
       updateFilePath = updateFilePath.mid(7);
    }
    ImageProcessorRunnable *runnable = new ImageProcessorRunnable(updateFilePath, type,ImageProcessorRunnable::Process_Update);
    connect(runnable, SIGNAL(finished()), this, SLOT(slotFinished()));

    QThreadPool::globalInstance()->start(runnable);
}

float Processor::initialProgress() const
{
    if (m_numFiles) {
        return 1.0f - (m_files.size() * 1.0f / m_numFiles);
    }

    return 0;
}

int Processor::numFiles() const
{
    return m_numFiles;
}

void Processor::process()
{
    if (m_processing)
        return;

    if (m_files.isEmpty()) {
        return;
    }
    m_processing = true;
    QPair<Types::MimeType, QString> pair = m_files.takeLast();
    Types::MimeType type = pair.first;
    QString path = pair.second;

    ImageProcessorRunnable *runnable = new ImageProcessorRunnable(path, type,&m_geoCoder);
    connect(runnable, SIGNAL(finished()), this, SLOT(slotFinished()));

    QThreadPool::globalInstance()->start(runnable);
}

void Processor::slotFinished()
{
    m_numFiles--;
    m_processing = false;
    QTimer::singleShot(0, this, SLOT(process()));
    emit initialProgressChanged();
    m_commitTimer.start();
}

void Processor::initialScanCompleted()
{
    m_initialScanDone = true;
    if (m_files.isEmpty()) {
        m_isFinished = true;
        emit finishedChanged();
    }
}

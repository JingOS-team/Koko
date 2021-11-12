/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: (C) 2021  Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <QObject>
#include <QStringList>
#include <QPair>
#include "committimer.h"
#include "reversegeocoder.h"
#include "types.h"

namespace JingGallery
{
class Processor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(float initialProgress READ initialProgress NOTIFY initialProgressChanged)
    Q_PROPERTY(int numFiles READ numFiles NOTIFY numFilesChanged)
    Q_PROPERTY(bool finished READ finished NOTIFY finishedChanged)
public:
    Processor(QObject *parent = 0);
    ~Processor();

    float initialProgress() const;
    int numFiles() const;

    bool finished() const
    {
        return m_isFinished;
    }

signals:
    void initialProgressChanged();
    void numFilesChanged();
    void finishedChanged();

public slots:
    void addFile(const QString &filePath, Types::MimeType type);
    void removeFile(const QList<QString> &filePaths);
    void initialScanCompleted();
    void updateFile(const QString &filePath, Types::MimeType type);

private slots:
    void process();
    void slotFinished();

private:
    QList<QPair<Types::MimeType, QString>> m_files;
    int m_numFiles;
    bool m_processing;

    CommitTimer m_commitTimer;
    ReverseGeoCoder m_geoCoder;
    bool m_initialScanDone;
    bool m_isFinished = false;
};

}
#endif // PROCESSOR_H

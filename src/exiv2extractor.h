/*
 * SPDX-FileCopyrightText: (C) 2012-2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2021 Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef EXIV2EXTRACTOR_H
#define EXIV2EXTRACTOR_H

#include <exiv2/exiv2.hpp>
#include <QDateTime>
#include <QString>

class Exiv2Extractor
{
public:
    Exiv2Extractor();

    void extract(const QString &filePath);

    double gpsLatitude()
    {
        return m_latitude;
    }
    double gpsLongitude()
    {
        return m_longitude;
    }
    QDateTime dateTime()
    {
        return m_dateTime;
    }

    bool error() const;

    bool setFileDateTime(QString locationPath,QString newFilePath);

private:
    double fetchGpsDouble(const Exiv2::ExifData &data, const char *name);
    QByteArray fetchByteArray(const Exiv2::ExifData &data, const char *name);

    double m_latitude;
    double m_longitude;
    QDateTime m_dateTime;

    bool m_error;
};

#endif // EXIV2EXTRACTOR_H

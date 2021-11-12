/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef ITEMTYPES_H
#define ITEMTYPES_H
#include <QObject>

class Types : public QObject
{
    Q_OBJECT
    Q_ENUMS(ItemTypes)
    Q_ENUMS(TimeGroup)
    Q_ENUMS(LocationGroup)
    Q_ENUMS(QueryType)
    Q_ENUMS(MimeType)
public:
    Types(QObject *parent);
    ~Types();

    enum ItemTypes { Album = 0, Folder, Media };
    enum MimeType { Image = 0, Video, All };
    enum TimeGroup { Year = 3, Month, Week, Day };
    enum LocationGroup { Country = 7, State, City };
    enum QueryType { LocationQuery = 10, TimeQuery, MimeTypeQuery };
};

#endif

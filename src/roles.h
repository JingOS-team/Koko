/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef ROLES_H
#define ROLES_H

#include <QObject>

class Roles : public QObject
{
    Q_OBJECT
    Q_ENUMS(RoleNames)
public:
    Roles(QObject *parent);
    ~Roles();
    enum RoleNames { MediaUrlRole = Qt::UserRole + 1, MimeTypeRole, Thumbnail, ThumbnailPixmap, PreviewUrlRole, DurationRole, ItemTypeRole, FilesRole, FileCountRole, DateRole, SelectedRole, SourceIndex, DateTimeRole,MediaTypeRole };
};

#endif

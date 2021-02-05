/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: (C) 2021  Wangrui <Wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "qmlplugins.h"
#include "allmediasmodel.h"
#include "imagedocument.h"
#include "mediamodel.h"
#include "medialistmodel.h"
#include "mediamimetypemodel.h"
#include "notificationmanager.h"
#include "roles.h"
#include "sortmodel.h"
#include "tagmodel.h"
#include "types.h"
#include "photoimageitem.h"

#include <QtQml/qqml.h>

void QmlPlugins::initializeEngine(QQmlEngine *engine, const char *)
{
}

void QmlPlugins::registerTypes(const char *uri)
{
#if QT_VERSION < QT_VERSION_CHECK(5, 14, 0)
    qmlRegisterType<QAbstractItemModel>();
#else
    qmlRegisterAnonymousType<QAbstractItemModel>(uri, 0);
#endif
    qmlRegisterType<QImageItem>(uri, 0, 2, "QImageItem");
    qmlRegisterType<TagModel>(uri, 0, 2, "TagModel");
    qmlRegisterType<MediaModel>(uri, 0, 2, "MediaModel");
    qmlRegisterType<AllMediasModel>(uri, 0, 2, "AllMediasModel");
    qmlRegisterType<Jungle::SortModel>(uri, 0, 2, "SortModel");
    qmlRegisterType<MediaListModel>(uri, 0, 2, "MediaListModel");
    qmlRegisterType<MediaMimeTypeModel>(uri, 0, 2, "MediaMimeTypeModel");
    qmlRegisterType<ImageDocument>(uri, 0, 2, "ImageDocument");
    qmlRegisterType<NotificationManager>(uri, 0, 2, "NotificationManager");
    qmlRegisterUncreatableType<Types>(uri, 0, 2, "Types", "Cannot instantiate the Types class");
    qmlRegisterUncreatableType<Roles>(uri, 0, 2, "Roles", "Cannot instantiate the Roles class");
}

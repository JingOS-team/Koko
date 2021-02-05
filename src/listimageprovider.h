/*
 * SPDX-FileCopyrightText: (C) 2021 Wang Rui <wangrui@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef LISTIMAGEPROVIDER_H
#define LISTIMAGEPROVIDER_H
#include <QQuickImageProvider>
#include <QDebug>
#include <kimagecache.h>
#include <QTimer>
#include <kdirmodel.h>
#include "mediastorage.h"
class ListImageProvider: public QQuickImageProvider
{
public:
    ListImageProvider(ImageType type, Flags flags = Flags()) :
        QQuickImageProvider(type, flags)
    {
        m_imageCache = MediaStorage::instance()->m_imageCache;
    };

    ~ListImageProvider() {}
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) {
        QStringList idAll = id.split("*");
        QUrl thumbnailSource(idAll[0]);
        KFileItem item(thumbnailSource, QString());
        QPixmap preview;
        if (m_imageCache->findPixmap(item.url().toString(), &preview)) {
            return preview;
        }
        return {};
    }
private:
    KImageCache *m_imageCache;

};

#endif // LISTIMAGEPROVIDER_H

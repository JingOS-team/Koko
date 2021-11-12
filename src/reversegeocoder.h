/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: (C) Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef KOKO_REVERSEGEOCODER_H
#define KOKO_REVERSEGEOCODER_H

#include <QVariantMap>
#include <kdtree.h>

namespace JingGallery
{
class ReverseGeoCoder
{
public:
    ReverseGeoCoder();
    ~ReverseGeoCoder();

    void init();
    bool initialized();

    /**
     * The ReverseGeoCoder consumes a significant amount of memory (around 100mb). It
     * makes sense to deinit it when it is not being used.
     */
    void deinit();

    QVariantMap lookup(double lat, double lon) const;

private:
    kdtree *m_tree;
    QMap<QString, QString> m_countryMap;
    QMap<QString, QString> m_admin1Map;
    QMap<QString, QString> m_admin2Map;
};
}

#endif // KOKO_REVERSEGEOCODER_H

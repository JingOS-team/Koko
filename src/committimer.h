/*
 * Copyright (C) 2015  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifndef KOKO_COMMITTIMER_H
#define KOKO_COMMITTIMER_H

#include <QTimer>
#include <QObject>

namespace Koko {

class CommitTimer : public QObject
{
    Q_OBJECT
public:
    explicit CommitTimer(QObject* parent = 0);

public slots:
    void start();

signals:
    void timeout();

private slots:
    void slotTimeout();

private:
    QTimer m_smallTimer;
    QTimer m_largeTimer;
};
}

#endif // KOKO_COMMITTIMER_H

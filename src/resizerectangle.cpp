/*
 * SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *                             Zhang He Gang <zhanghegang@jingos.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "resizerectangle.h"

#include <cmath>

ResizeRectangle::ResizeRectangle(QQuickItem *parent)
    : QQuickItem(parent)
{
    setAcceptedMouseButtons(Qt::LeftButton);
}

void ResizeRectangle::mouseReleaseEvent(QMouseEvent *event)
{
    if(m_moveArea.width() == width() && m_moveArea.height() == height()){
        event->ignore();
    }else {
        event->accept();
        Q_EMIT moveRect(false);
    }
}

void ResizeRectangle::mousePressEvent(QMouseEvent *event)
{
    if(m_moveArea.width() == width() && m_moveArea.height() == height()){
        event->ignore();
    }else {
        m_mouseDownPosition = event->windowPos();
        m_mouseDownGeometry = QPointF(x(), y());
        event->accept();
    }
}

void ResizeRectangle::mouseMoveEvent(QMouseEvent *event)
{
    if(!isMutilPoint){
        const QPointF difference = m_mouseDownPosition - event->windowPos();
        const qreal x = m_mouseDownGeometry.x() - difference.x();
        const qreal y = m_mouseDownGeometry.y() - difference.y();
        m_currentArea = QRectF(x,y,width(),height());
        bool leftTop = m_moveArea.contains(m_currentArea);
        if(leftTop){
            setX(x);
            setY(y);
            Q_EMIT moveRect(true);
        } else {
            if(m_currentArea.x() < m_moveArea.x()){
                setX(m_moveArea.x());
            }else if((m_currentArea.x() + m_currentArea.width()) > (m_moveArea.x() + m_moveArea.width())){
                setX(m_moveArea.x() + m_moveArea.width() - m_currentArea.width());
            }else {
                setX(x);
            }

            if (m_currentArea.y() < m_moveArea.y()) {
                setY(m_moveArea.y());
            } else if((m_currentArea.y() + m_currentArea.height()) > (m_moveArea.y() + m_moveArea.height())) {
                setY(m_moveArea.y() + m_moveArea.height() - m_currentArea.height());
            } else {
                setY(y);
            }
        }
        event->accept();
    } else {
      event->ignore();
      Q_EMIT moveRect(false);
    }
}

void ResizeRectangle::mouseDoubleClickEvent(QMouseEvent *event)
{
    Q_EMIT acceptSize();
    event->ignore();
}

void ResizeRectangle::touchEvent(QTouchEvent *event)
{
  isMutilPoint = event->touchPoints().size() > 1;
  event->ignore();
}

void ResizeRectangle::onWidthChanged()
{
    m_currentArea = QRectF(x(),y(),width(),height());
}

#include "moc_resizerectangle.cpp"

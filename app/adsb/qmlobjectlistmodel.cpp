/****************************************************************************
 *
 * This file has been ported from QGroundControl project <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "qmlobjectlistmodel.h"

#include <QDebug>
#include <QQmlEngine>

const int QmlObjectListModel::ObjectRole = Qt::UserRole;
const int QmlObjectListModel::TextRole = Qt::UserRole + 1;

QmlObjectListModel::QmlObjectListModel(QObject* parent)
    : QAbstractListModel        (parent)
    , _dirty                    (false)
    , _skipDirtyFirstItem       (false)
    , _externalBeginResetModel  (false)
{

}

QmlObjectListModel::~QmlObjectListModel()
{

}

QObject* QmlObjectListModel::get(int index)
{
    if (index < 0 || index >= _objectList.count()) {
        return nullptr;
    }
    return _objectList[index];
}

int QmlObjectListModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : _objectList.count();
}

QVariant QmlObjectListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    if (index.row() < 0 || index.row() >= _objectList.count()) {
        return QVariant();
    }

    if (role == ObjectRole) {
        return QVariant::fromValue(_objectList[index.row()]);
    } else if (role == TextRole) {
        return QVariant::fromValue(_objectList[index.row()]->objectName());
    } else {
        return QVariant();
    }
}

QHash<int, QByteArray> QmlObjectListModel::roleNames(void) const
{
    QHash<int, QByteArray> hash;

    hash[ObjectRole] = "object";
    hash[TextRole] = "text";

    return hash;
}

bool QmlObjectListModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (index.isValid() && role == ObjectRole) {
        _objectList.replace(index.row(), value.value<QObject*>());
        emit dataChanged(index, index);
        return true;
    }

    return false;
}

bool QmlObjectListModel::removeRows(int position, int rows, const QModelIndex& parent)
{
    if (parent.isValid() || position < 0 || rows <= 0
            || position > _objectList.count() || rows > _objectList.count() - position) {
        return false;
    }

    beginRemoveRows(QModelIndex(), position, position + rows - 1);
    for (int row=0; row<rows; row++) {
        _objectList.removeAt(position);
    }
    endRemoveRows();

    emit countChanged(count());

    return true;
}

QObject* QmlObjectListModel::operator[](int index)
{
    if (index < 0 || index >= _objectList.count()) {
        return nullptr;
    }
    return _objectList[index];
}

const QObject* QmlObjectListModel::operator[](int index) const
{
    if (index < 0 || index >= _objectList.count()) {
        return nullptr;
    }
    return _objectList[index];
}

void QmlObjectListModel::clear()
{
    if (!_externalBeginResetModel) {
        beginResetModel();
    }
    _objectList.clear();
    if (!_externalBeginResetModel) {
        endResetModel();
        emit countChanged(count());
    }
}

QObject* QmlObjectListModel::removeAt(int i)
{
    if (i < 0 || i >= _objectList.count()) return nullptr;
    QObject* removedObject = _objectList[i];
    if(removedObject) {
        // Look for a dirtyChanged signal on the object
        if (_objectList[i]->metaObject()->indexOfSignal(QMetaObject::normalizedSignature("dirtyChanged(bool)")) != -1) {
            if (!_skipDirtyFirstItem || i != 0) {
                QObject::disconnect(_objectList[i], SIGNAL(dirtyChanged(bool)), this, SLOT(_childDirtyChanged(bool)));
            }
        }
    }
    removeRows(i, 1);
    setDirty(true);
    return removedObject;
}

void QmlObjectListModel::insert(int i, QObject* object)
{
    insert(i, QList<QObject*>{object});
}

void QmlObjectListModel::insert(int i, QList<QObject*> objects)
{
    if (i < 0 || i > _objectList.count() || objects.isEmpty() || objects.contains(nullptr)) return;

    int j = i;
    for (QObject* object: objects) {
        QQmlEngine::setObjectOwnership(object, QQmlEngine::CppOwnership);

        // Look for a dirtyChanged signal on the object
        if (object->metaObject()->indexOfSignal(QMetaObject::normalizedSignature("dirtyChanged(bool)")) != -1) {
            if (!_skipDirtyFirstItem || j != 0) {
                QObject::connect(object, SIGNAL(dirtyChanged(bool)), this, SLOT(_childDirtyChanged(bool)));
            }
        }
        j++;
    }

    // Views must see the old contents during rowsAboutToBeInserted.
    beginInsertRows(QModelIndex(), i, i + objects.count() - 1);
    j = i;
    for (QObject* object : objects) _objectList.insert(j++, object);
    endInsertRows();
    emit countChanged(count());

    setDirty(true);
}

void QmlObjectListModel::append(QObject* object)
{
    insert(_objectList.count(), object);
}

void QmlObjectListModel::append(QList<QObject*> objects)
{
    insert(_objectList.count(), objects);
}

QObjectList QmlObjectListModel::swapObjectList(const QObjectList& newlist)
{
    QObjectList oldlist(_objectList);
    if (!_externalBeginResetModel) {
        beginResetModel();
    }
    _objectList = newlist;
    if (!_externalBeginResetModel) {
        endResetModel();
        emit countChanged(count());
    }
    return oldlist;
}

int QmlObjectListModel::count() const
{
    return rowCount();
}

void QmlObjectListModel::setDirty(bool dirty)
{
    if (_dirty != dirty) {
        _dirty = dirty;
        if (!dirty) {
            // Need to clear dirty from all children
            for(QObject* object: _objectList) {
                if (object->property("dirty").isValid()) {
                    object->setProperty("dirty", false);
                }
            }
        }
        emit dirtyChanged(_dirty);
    }
}

void QmlObjectListModel::_childDirtyChanged(bool dirty)
{
    _dirty |= dirty;
    // We want to emit dirtyChanged even if the actual value of _dirty didn't change. It can be a useful
    // signal to know when a child has changed dirty state
    emit dirtyChanged(_dirty);
}

void QmlObjectListModel::deleteListAndContents()
{
    for (int i=0; i<_objectList.count(); i++) {
        _objectList[i]->deleteLater();
    }
    deleteLater();
}

void QmlObjectListModel::clearAndDeleteContents()
{
    for (int i=0; i<_objectList.count(); i++) {
        _objectList[i]->deleteLater();
    }
    clear();
}

void QmlObjectListModel::beginReset()
{
    if (_externalBeginResetModel) {
        qWarning() << "QmlObjectListModel::beginReset already set";
    }
    _externalBeginResetModel = true;
    beginResetModel();
}

void QmlObjectListModel::endReset()
{
    if (!_externalBeginResetModel) {
        qWarning() << "QmlObjectListModel::endReset begin not set";
    }
    _externalBeginResetModel = false;
    endResetModel();
}

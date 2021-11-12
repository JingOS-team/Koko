#
# Common Library
#
set(LIB_SRCS
    mediastorage.cpp
    filesystemmediafetcher.cpp
    exiv2extractor.cpp
    ${LIB_SRCS}
)

add_library(jinggallerycommon SHARED ${LIB_SRCS})
target_link_libraries(jinggallerycommon
    Qt5::Core
    Qt5::Sql
    KF5::CoreAddons
    KF5::KIOCore
    KF5::KIOFileWidgets
    KF5::KIOWidgets
    KF5::Notifications
    KF5::GuiAddons
    mediainfo
    LibExiv2::LibExiv2

)

generate_export_header(jinggallerycommon BASE_NAME JINGGALLERY EXPORT_FILE_NAME jinggallery_export.h)
set_target_properties(jinggallerycommon PROPERTIES
    VERSION 0.0.2
    SOVERSION 0.0.2
)

install(TARGETS jinggallerycommon EXPORT JinggalleryLibraryTargets ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# Application
#

set(jinggallery_SRCS
    main.cpp
    reversegeocoder.cpp
    filesystemtracker.cpp
    processor.cpp
    committimer.cpp
    imageprocessorrunnable.cpp
    exiv2extractor.cpp
    kdtree.c
    resizehandle.cpp
    resizerectangle.cpp
    resources.qrc
    listimageprovider.cpp
)

kconfig_add_kcfg_files(jinggallery_SRCS jinggalleryconfig.kcfgc GENERATE_MOC)

add_executable(jinggallery ${jinggallery_SRCS})

target_link_libraries(jinggallery
    Qt5::QuickControls2
    Qt5::Quick
    Qt5::Widgets
    Qt5::Qml
    Qt5::DBus
    KF5::ConfigCore
    KF5::DBusAddons
    KF5::I18n
    KF5::CoreAddons
    KF5::KIOCore
    KF5::ConfigGui
    jinggallerycommon
    LibExiv2::LibExiv2
    mediainfo
    KF5::Notifications
    KF5::GuiAddons
    KF5::KIOFileWidgets
    KF5::KIOWidgets
    jappcoreqt
)

if (ANDROID)
    target_link_libraries(jinggallery Qt5::AndroidExtras)
endif ()

install(TARGETS jinggallery ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# QML Plugin
#
set (qml_plugin_SRCS
    qmlplugins.cpp
    tagmodel.cpp
    mediamodel.cpp
    sortmodel.cpp
    allmediasmodel.cpp
    medialistmodel.cpp
    mediamimetypemodel.cpp
    notificationmanager.cpp
    types.cpp
    roles.cpp
    exiv2extractor.cpp
    imagedocument.cpp
    photoimageitem.cpp
    imagesavethread.cpp
)

add_library (jinggalleryqmlplugin SHARED ${qml_plugin_SRCS})

target_link_libraries (jinggalleryqmlplugin
    Qt5::Qml
    Qt5::Quick
    KF5::KIOCore
    KF5::KIOFileWidgets
    KF5::KIOWidgets
    KF5::GuiAddons
    KF5::I18n
    KF5::Notifications
    jinggallerycommon
    LibExiv2::LibExiv2
    KF5::ConfigCore
)

install (TARGETS jinggalleryqmlplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/jinggallery)
install (FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/jinggallery)

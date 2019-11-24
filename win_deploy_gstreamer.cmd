
SET DESTDIR_WIN=%~f1

set GST_ROOT_WIN="C:/gstreamer/1.0/x86_64"


xcopy %GST_ROOT_WIN%\bin\*.dll %DESTDIR_WIN%\ /S/Y
xcopy %GST_ROOT_WIN%\bin\*. %DESTDIR_WIN%\ /S/Y
xcopy %GST_ROOT_WIN%\lib\gstreamer-1.0\*.dll %DESTDIR_WIN%\gstreamer-plugins\ /Y
xcopy %GST_ROOT_WIN%\lib\gstreamer-1.0\validate\*.dll %DESTDIR_WIN%\gstreamer-plugins\validate\ /Y

   
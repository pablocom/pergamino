@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >/dev/null 2>&1
echo CL location:
where cl
echo.
echo Running mix:
cd /d C:\src\pergamino\server
mix deps.compile snappyer --force 2>&1
echo EXIT CODE: %ERRORLEVEL%

@echo off
echo ====================================
echo Pergamino Deep Link Test Script
echo ====================================
echo.

REM Check if ADB is available
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ADB not found in PATH
    echo.
    echo Please add Android SDK platform-tools to your PATH:
    echo Usually located at: C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools
    echo.
    pause
    exit /b 1
)

echo Checking for connected devices...
adb devices
echo.

if "%1"=="" (
    echo Usage: test-deep-link.bat YOUR_TOKEN_HERE
    echo.
    echo Example: test-deep-link.bat abc-123-def-456
    echo.
    echo To get the token:
    echo   1. Run the app in Android Studio
    echo   2. Enter email and tap Continue
    echo   3. Check Logcat (filter: FakeAuthRemoteDataSource^)
    echo   4. Copy the token from the logged deep link
    echo.
    pause
    exit /b 1
)

set TOKEN=%1
echo Sending deep link with token: %TOKEN%
echo.

adb shell am start -a android.intent.action.VIEW -d "pergamino://verify?token=%TOKEN%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Deep link sent successfully!
    echo.
    echo Check the app - you should see the success screen.
) else (
    echo.
    echo ✗ Failed to send deep link
    echo.
    echo Make sure:
    echo   1. Emulator or device is connected
    echo   2. App is installed and running
    echo   3. Token is correct
)

echo.
pause

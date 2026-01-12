@echo off
echo ====================================
echo Running Pergamino Unit Tests
echo ====================================
echo.

cd android

echo Running all unit tests...
echo.

call gradlew.bat test

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✓ All tests passed successfully!
    echo ========================================
    echo.
    echo View detailed report:
    echo feature-auth\build\reports\tests\testDebugUnitTest\index.html
    echo.
) else (
    echo.
    echo ========================================
    echo ✗ Some tests failed
    echo ========================================
    echo.
    echo Check the output above for details
    echo.
)

pause

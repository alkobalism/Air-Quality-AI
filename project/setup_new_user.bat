@echo off
setlocal
cd /d "%~dp0"

echo ===================================================
echo     Setting up Air Quality AI for New User
echo ===================================================

REM 0. Check for Admin Privileges (Required for Long Paths fix)
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges to enable Long Paths...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

REM 0a. Change directory AGAIN after admin elevation (just in case)
cd /d "%~dp0"

REM 0b. Enable Long Paths (Fix for deep TensorFlow paths)
echo Enabling Windows Long Paths Support...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul
if %errorlevel% equ 0 (
    echo Long Paths Enabled.
) else (
    echo WARNING: Failed to enable Long Paths. You might see installation errors.
)
echo.

REM 1. Check for compatible Python version (3.10 - 3.11)
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) and sys.version_info < (3, 12) else 1)" >nul 2>&1
if %errorlevel% equ 0 goto :FOUND_PYTHON

echo.
echo Python 3.10 or 3.11 was not found in your PATH.
echo We will attempt to automatically install Python 3.11 for you.
echo.

REM 2. Try Winget Installation
echo [Method 1] Attempting installation via Winget...
winget install -e --id Python.Python.3.11 --scope machine --accept-source-agreements --accept-package-agreements
if %errorlevel% equ 0 goto :INSTALLED_SUCCESS

REM 3. Try Direct Download via PowerShell
echo.
echo Winget failed or is not available.
echo [Method 2] Attempting direct download from python.org...
echo Downloading Python 3.11 installer...
powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile 'python_installer.exe'"

if not exist "python_installer.exe" (
    echo.
    echo ERROR: Failed to download the installer.
    goto :MANUAL_INSTALL
)

echo Installing Python... (Please click 'Yes' if asked for permission)
python_installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Installation failed.
    del python_installer.exe
    goto :MANUAL_INSTALL
)

del python_installer.exe
echo.
goto :INSTALLED_SUCCESS

:INSTALLED_SUCCESS
echo ===================================================
echo Python 3.11 has been successfully installed!
echo.
echo IMPORTANT: You MUST restart this script for the changes to take effect.
echo Please close this window and run 'setup_new_user.bat' again.
echo ===================================================
timeout /t 10
exit /b 0

:MANUAL_INSTALL
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo ERROR: Automatic installation failed.
echo Please install Python 3.11 manually from:
echo https://www.python.org/downloads/release/python-3119/
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo Opening download page...
start https://www.python.org/downloads/release/python-3119/
pause
exit /b 1

:FOUND_PYTHON
echo Python version is compatible. Proceeding...
echo.

if not exist "tf_env" (
    echo [1/3] Creating virtual environment...
    python -m venv tf_env
) else (
    echo [1/3] Virtual environment already exists.
)

echo [2/3] Installing dependencies (this may take a few minutes)...
".\tf_env\Scripts\python.exe" -m pip install --upgrade pip
".\tf_env\Scripts\python.exe" -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo.
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo ERROR: Failed to install dependencies.
    echo Please check your internet connection or error messages above.
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    pause
    exit /b %errorlevel%
)

echo [3/3] Starting App...
echo ===================================================
echo Open your browser to: http://127.0.0.1:5000
echo ===================================================
".\tf_env\Scripts\python.exe" app.py
pause

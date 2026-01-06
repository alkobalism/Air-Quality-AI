@echo off
echo ===================================================
echo     Setting up Air Quality AI for the first time
echo ===================================================

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

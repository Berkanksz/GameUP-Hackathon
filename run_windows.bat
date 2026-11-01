@echo off
title Higher Ground - Launcher
echo ========================================================
echo Higher Ground: Iklim Yolculugu / Climate Journey
echo ========================================================
echo.

where godot >nul 2>nul
if %ERRORLEVEL% equ 0 (
    godot --path .
    exit /b 0
)

where godot4 >nul 2>nul
if %ERRORLEVEL% equ 0 (
    godot4 --path .
    exit /b 0
)

if exist "godot.exe" (
    .\godot.exe --path .
    exit /b 0
)

echo [INFO] Godot 4 executable was not automatically found in PATH.
echo To play on Windows:
echo 1. Download Godot 4 (standard version) from https://godotengine.org/download/windows/
echo 2. Open Godot, click 'Import', and select 'project.godot' from this folder.
echo 3. Click 'Run' (or press F5).
echo.
pause

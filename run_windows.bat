@echo off
setlocal enabledelayedexpansion
title Higher Ground - Launcher
cd /d "%~dp0"

echo ========================================================
echo Higher Ground: Iklim Yolculugu / Climate Journey
echo ========================================================
echo.

set "GODOT_CMD="
if exist "HigherGround.exe" set "GODOT_CMD=.\HigherGround.exe"
if not defined GODOT_CMD if exist "godot.exe" set "GODOT_CMD=.\godot.exe"

if not defined GODOT_CMD (
    where godot >nul 2>nul
    if %ERRORLEVEL% equ 0 set "GODOT_CMD=godot"
)

if not defined GODOT_CMD (
    where godot4 >nul 2>nul
    if %ERRORLEVEL% equ 0 set "GODOT_CMD=godot4"
)

if not defined GODOT_CMD (
    echo [BILGI / INFO] Bilgisayarinizda Godot bulunamadi.
    echo Oyun motoru otomatik olarak indiriliyor (tek seferlik, ~40 MB)...
    echo Downloading portable game runner, please wait...
    echo.
    where curl >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        curl -L -o godot_win.zip "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip"
        if exist "godot_win.zip" (
            tar -xf godot_win.zip
            del /f /q godot_win.zip
            ren Godot*_win64.exe HigherGround.exe 2>nul
        )
    ) else (
        powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip' -OutFile 'godot_win.zip'; Expand-Archive -Path 'godot_win.zip' -DestinationPath '.' -Force; Remove-Item 'godot_win.zip' -Force; Get-ChildItem -Filter 'Godot*.exe' | Rename-Item -NewName 'HigherGround.exe' -Force"
    )
    if exist "HigherGround.exe" set "GODOT_CMD=.\HigherGround.exe"
)

if not defined GODOT_CMD (
    echo.
    echo [HATA / ERROR] Otomatik indirme basarisiz oldu.
    echo Lutfen https://godotengine.org/download/windows/ adresinden Godot indirin
    echo ve 'godot.exe' dosyasini bu klasore kopyalayin.
    echo.
    pause
    exit /b 1
)

:: Ilk calistirmada varliklarin taranmasi ve derlenmesi
if not exist ".godot\imported" (
    echo.
    echo Ilk calistirma hazirligi yapiliyor (varliklar derleniyor, 2-3 saniye)...
    echo Preparing assets for first run, please wait...
    %GODOT_CMD% --headless --editor --quit --path .
)

echo.
echo Oyun baslatiliyor / Launching game...
%GODOT_CMD% --path .
if %ERRORLEVEL% neq 0 (
    echo.
    pause
)

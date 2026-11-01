@echo off
title Higher Ground - Launcher
echo ========================================================
echo Higher Ground: Iklim Yolculugu / Climate Journey
echo ========================================================
echo.

set "GODOT_CMD="
where godot >nul 2>nul
if %ERRORLEVEL% equ 0 set "GODOT_CMD=godot"

if not defined GODOT_CMD (
    where godot4 >nul 2>nul
    if %ERRORLEVEL% equ 0 set "GODOT_CMD=godot4"
)

if not defined GODOT_CMD (
    if exist "godot.exe" set "GODOT_CMD=.\godot.exe"
)

if not defined GODOT_CMD (
    echo [HATA / ERROR] Godot 4 executable was not found.
    echo Please install Godot 4: https://godotengine.org/download/windows/
    echo Or open Godot 4 and import 'project.godot' from this folder.
    echo.
    pause
    exit /b 1
)

:: Ilk calistirmada varliklarin ice aktarilmasi (First-time asset import)
if not exist ".godot\imported" (
    echo Ilk calistirma hazirligi yapiliyor (varliklar ice aktariliyor)...
    %GODOT_CMD% --headless --editor --quit --path .
)

:: Oyunu baslat
%GODOT_CMD% --path .

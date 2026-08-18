@echo off
setlocal EnableDelayedExpansion
title Atmosphere Builder Menu

rem ---------------------------------------------------------------
rem Interactive build menu for Atmosphere.
rem Uses the devkitPro MSYS2 environment (C:\devkitPro\msys2).
rem Build runs with -j2 by default to avoid hogging the CPU.
rem See BUILD_NOTES.md in this folder for the full explanation.
rem ---------------------------------------------------------------

set "BASH=C:\devkitPro\msys2\usr\bin\bash.exe"
set "SCRIPT=/c/PROJECTS/switch/switch-cfw/atmosphere/build.sh"
set "JOBS=2"

if not exist "%BASH%" (
    echo ERROR: devkitPro MSYS2 bash not found at:
    echo   %BASH%
    echo Install devkitPro first: https://devkitpro.org
    pause
    exit /b 1
)

:menu
cls
echo ============================================
echo      Atmosphere Build Menu
echo      Repo: C:\PROJECTS\switch\switch-cfw\atmosphere
echo      Jobs: %JOBS%
echo ============================================
echo.
echo   1) Build nx_release        (release, normal build)
echo   2) Build nx_debug          (debug build)
echo   3) Build + SD zip          (dist-no-debug-nx_release, produces install zip + packages _ZIPS_/atmosphere-release.zip)
echo   4) Dry run                 (shows what would be rebuilt, no compile)
echo   5) Set job count           (currently %JOBS%)
echo   6) Clean                   (remove all build artifacts)
echo.
echo   0) Quit
echo.
set /p CHOICE="Select an option: "

if "%CHOICE%"=="1" ( set "TARGET=nx_release" & goto build )
if "%CHOICE%"=="2" ( set "TARGET=nx_debug" & goto build )
if "%CHOICE%"=="3" ( set "TARGET=dist-no-debug-nx_release" & goto build )
if "%CHOICE%"=="4" ( set "TARGET=nx_release" & set "DRYRUN=1" & goto build )
if "%CHOICE%"=="5" goto jobs
if "%CHOICE%"=="6" ( set "TARGET=clean" & goto build )
if "%CHOICE%"=="0" exit /b 0
echo Invalid choice. & timeout /t 1 >nul & goto menu

:jobs
echo.
set /p JOBS="Enter job count (parallel make jobs): "
if "%JOBS%"=="" set "JOBS=2"
goto menu

:build
echo.
echo == Building: target=%TARGET% jobs=%JOBS% ==
if defined DRYRUN (
    "%BASH%" -lc "bash '%SCRIPT%' '%TARGET%' '%JOBS%' --dryrun"
) else (
    "%BASH%" -lc "bash '%SCRIPT%' '%TARGET%' '%JOBS%'"
)
echo.
if errorlevel 1 (
    echo == BUILD FAILED - see output above ==
) else (
    echo == DONE ==
)
set "DRYRUN="
pause
goto menu

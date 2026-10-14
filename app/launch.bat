@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo Application Shiny - Modelisation Chlordecone
echo ============================================
echo.

REM 1) Rscript dans le PATH, 2) sinon la version de R la plus recente dans Program Files
set "RSCRIPT="
where Rscript >nul 2>nul && set "RSCRIPT=Rscript"

if not defined RSCRIPT (
    for /f "delims=" %%d in ('dir /b /ad /o-n "%ProgramFiles%\R\R-*" 2^>nul') do (
        if not defined RSCRIPT if exist "%ProgramFiles%\R\%%d\bin\Rscript.exe" set "RSCRIPT=%ProgramFiles%\R\%%d\bin\Rscript.exe"
    )
)

if not defined RSCRIPT (
    echo ERREUR: R n'a pas ete trouve sur votre systeme.
    echo Installez R depuis https://cran.r-project.org/ ou ajoutez Rscript.exe au PATH.
    pause
    exit /b 1
)

echo R trouve: %RSCRIPT%
echo.
echo Lancement de l'application (Ctrl+C pour arreter)...
echo.

"%RSCRIPT%" --vanilla run.R

pause

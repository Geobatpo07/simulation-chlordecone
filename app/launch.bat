@echo off
echo ============================================
echo Application Shiny - Modelisation Chlordecone
echo ============================================
echo.
echo Lancement de l'application...
echo.

REM Recherche de R dans les emplacements courants
set R_PATHS=^
"C:\Program Files\R\R-4.3.2\bin\R.exe"^
"C:\Program Files\R\R-4.3.1\bin\R.exe"^
"C:\Program Files\R\R-4.3.0\bin\R.exe"^
"C:\Program Files\R\R-4.2.3\bin\R.exe"^
"C:\Program Files\R\R-4.2.2\bin\R.exe"^
"C:\Program Files\R\R-4.2.1\bin\R.exe"^
"C:\Program Files\R\R-4.1.3\bin\R.exe"

set R_EXE=

for %%p in (%R_PATHS%) do (
    if exist %%p (
        set R_EXE=%%p
        goto :found
    )
)

:found
if "%R_EXE%"=="" (
    echo ERREUR: R n'a pas ete trouve sur votre systeme
    echo Veuillez installer R depuis https://cran.r-project.org/
    echo Ou specifier manuellement le chemin vers R.exe
    pause
    exit /b 1
)

echo R trouve: %R_EXE%
echo.

REM Lancement de l'application
%R_EXE% --vanilla --quiet -e "shiny::runApp(launch.browser=TRUE)"

pause

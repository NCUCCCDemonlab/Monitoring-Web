@echo off
setlocal
rem ============================================================
rem  Tuchang GNSS daily sync (run on a Taiwan/campus-network PC)
rem  Updates gnss.json + summary.json and pushes to GitHub.
rem  Pure ASCII on purpose: cmd.exe on zh-TW Windows misreads
rem  Chinese in .bat files, so keep this file English-only.
rem  A step-by-step log is written to scripts\sync_gnss.log
rem ============================================================
set "LOG=%~dp0sync_gnss.log"
echo ============================================================> "%LOG%"
echo Run time: %date% %time%>> "%LOG%"

rem Go to repo root (relative to this script, avoids path issues)
cd /d "%~dp0.."
echo Working dir: %cd%>> "%LOG%"

rem Load local secret (scripts\secrets.local.bat, gitignored)
if exist "%~dp0secrets.local.bat" (
  call "%~dp0secrets.local.bat"
  echo secrets.local.bat: loaded>> "%LOG%"
) else (
  echo [ERROR] secrets.local.bat not found>> "%LOG%"
  exit /b 1
)
if defined RMDGNSS_PASSWORD (echo RMDGNSS_PASSWORD: set>> "%LOG%") else (echo RMDGNSS_PASSWORD: NOT set>> "%LOG%")

where python >> "%LOG%" 2>&1
where git >> "%LOG%" 2>&1

echo --- git pull --->> "%LOG%"
git pull --rebase --autostash origin main >> "%LOG%" 2>&1

echo --- build_data.py gnss --->> "%LOG%"
python "%~dp0build_data.py" gnss >> "%LOG%" 2>&1
set "BUILD_RC=%errorlevel%"
echo build exit code: %BUILD_RC%>> "%LOG%"
if not "%BUILD_RC%"=="0" (
  echo [SKIP] GNSS fetch failed, not pushing>> "%LOG%"
  exit /b 1
)

git add data/gnss.json data/summary.json >> "%LOG%" 2>&1
git diff --cached --quiet && (
  echo No changes, done>> "%LOG%"
  exit /b 0
)
echo --- commit ^& push --->> "%LOG%"
git commit -m "chore: daily GNSS sync" >> "%LOG%" 2>&1
git push >> "%LOG%" 2>&1
echo push exit code: %errorlevel%>> "%LOG%"
echo [DONE] GNSS updated and pushed>> "%LOG%"
endlocal

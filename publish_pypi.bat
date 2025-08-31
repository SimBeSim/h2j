@echo off
setlocal ENABLEDELAYEDEXPANSION
REM ==========================================
REM h2j publisher: build + upload (PyPI/Test)
REM Usage:
REM   publish_pypi.bat           -> upload to PyPI
REM   publish_pypi.bat test      -> upload to TestPyPI
REM Requires:
REM   - TWINE_USERNAME=__token__
REM   - TWINE_PASSWORD=<your api token>
REM ==========================================

REM Choose repo
set REPO=pypi
if /I "%1"=="test" (
  set REPO_URL=https://test.pypi.org/legacy/
  set REPO=testpypi
) else (
  set REPO_URL=
  set REPO=pypi
)

REM Show version from h2j/__init__.py
for /f "usebackq tokens=2 delims== " %%v in (`findstr /R /C:"^__version__ *= *" h2j\__init__.py`) do (
  set RAW=%%v
)
set VER=%RAW:"=%

echo.
echo ==========================================
echo   h2j version: %VER%
if /I "%REPO%"=="testpypi" (
  echo   Target: TestPyPI
) else (
  echo   Target: PyPI
)
echo ==========================================
echo.

REM Ensure tools
python -m pip install -U pip >nul
python -m pip install -U build twine >nul

REM Clean old dists
if exist dist rmdir /s /q dist

REM Build
python -m build || goto :error

REM Upload
if /I "%REPO%"=="testpypi" (
  twine upload --repository-url https://test.pypi.org/legacy/ dist/* || goto :error
) else (
  twine upload dist/* || goto :error
)

REM Optional: tag and push the version
choice /M "Create and push git tag v%VER% ?" /C YN /N
if errorlevel 2 goto :end
git tag v%VER%
git push origin v%VER%

echo.
echo ✅ Done! Published h2j %VER% to %REPO%.
goto :end

:error
echo.
echo ❌ Publishing failed. Check the error above.
exit /b 1

:end
endlocal

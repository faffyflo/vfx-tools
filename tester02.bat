@echo off
setlocal enabledelayedexpansion

:: Check if a folder was dropped
if "%~1"=="" (
    echo Please drag and drop a folder onto this batch file.
    pause
    exit /b
)

if not exist "%~1\" (
    echo The provided path is not a valid folder.
    pause
    exit /b
)

cd /d "%~1"
echo Scanning folder: %~1
echo.

:: Array of extensions to check
set "extensions=png jpg jpeg exr tif tiff dpx"

:: Find image sequences
for %%e in (%extensions%) do (
    set "found=0"
    set "minframe=999999"
    set "basename="
    
    :: Look for files with 2-5 digit frame numbers
    for %%f in (*%%e) do (
        set "filename=%%~nf"
        set "ext=%%~xf"
        
        :: Try to extract frame number (2-5 digits at end of filename)
        for /l %%d in (5,-1,2) do (
            if not defined basename (
                call :extractFrame "!filename!" %%d "!ext!"
            )
        )
    )
    
    :: If we found a sequence, process it
    if defined basename (
        echo Found sequence: !basename!####!ext!
        echo Starting frame: !minframe!
        echo.
        
        if !minframe! gtr 0 (
            echo Renumbering sequence to start at frame 0...
            call :renumberSequence "!basename!" "!ext!" !minframe!
            echo Done!
            echo.
        ) else (
            echo Sequence already starts at frame 0, no changes needed.
            echo.
        )
        goto :end
    )
)

echo No image sequence found in this folder.
echo.
goto :end

:extractFrame
    set "fname=%~1"
    set "digits=%~2"
    set "fext=%~3"
    
    :: Get the last N characters
    set "lastchars=!fname:~-%digits%!"
    
    :: Check if they're all digits
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    if !errorlevel! equ 0 (
        set "frame=!lastchars!"
        set /a framenum=10000000!frame! %% 10000000
        
        :: Get basename (everything before frame number)
        call set "base=%%fname:~0,-%digits%%%"
        
        :: Check if this matches our current basename or if it's the first
        if not defined basename (
            set "basename=!base!"
            set "minframe=!framenum!"
            set "frameDigits=%digits%"
            set "found=1"
        ) else if "!base!"=="!basename!" (
            if !framenum! lss !minframe! (
                set "minframe=!framenum!"
            )
        )
    )
    exit /b

:renumberSequence
    set "base=%~1"
    set "ext=%~2"
    set "offset=%~3"
    
    :: Create temporary rename list
    set "tempfile=%temp%\rename_list_%random%.txt"
    
    :: First pass: collect all files and their new names
    for %%f in (%base%*%ext%) do (
        set "filename=%%~nf"
        
        :: Extract frame number
        for /l %%d in (5,-1,2) do (
            set "lastchars=!filename:~-%%d!"
            echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
            if !errorlevel! equ 0 (
                set /a oldframe=10000000!lastchars! %% 10000000
                set /a newframe=!oldframe!-%offset%
                
                :: Pad frame number
                set "padded=0000!newframe!"
                set "padded=!padded:~-%%d!"
                
                echo %%f|%base%!padded!%ext% >> "!tempfile!"
                goto :nextFile
            )
        )
        :nextFile
    )
    
    :: Second pass: rename using temp names first to avoid collisions
    for /f "tokens=1,2 delims=|" %%a in (!tempfile!) do (
        ren "%%a" "temp_%%b"
    )
    
    :: Third pass: remove temp_ prefix
    ren "temp_%base%*%ext%" "%base%*"
    
    del "!tempfile!"
    exit /b

:end
pause
@echo off
setlocal enabledelayedexpansion

:: Check if a folder was dropped on the script
if "%~1"=="" (
    echo Please drag and drop a folder onto this batch file.
    pause
    exit /b
)

:: Check if the dropped item is a directory
if not exist "%~1\*" (
    echo The dropped item is not a valid folder.
    pause
    exit /b
)

set "folder=%~1"
echo Working on folder: %folder%
echo.

:: Search for image sequences with different extensions and frame number patterns
set "found=0"
set "ext="
set "base="
set "digits="
set "start_num="

:: Check for each extension and digit pattern
for %%e in (png jpg jpeg exr tif tiff dpx) do (
    if !found!==0 (
        for %%d in (5 4 3 2) do (
            if !found!==0 (
                for %%f in ("%folder%\*.%%e") do (
                    set "filename=%%~nf"
                    call set "last_digits=%%filename:~-%%d%%"
                    
                    :: Check if last digits are all numbers
                    set "is_numeric=1"
                    for /f "delims=0123456789" %%a in ("!last_digits!") do set "is_numeric=0"
                    
                    :: Also check the length matches
                    set "check=!last_digits!"
                    set "len=0"
                    :count_loop
                    if defined check (
                        set "check=!check:~1!"
                        set /a len+=1
                        goto count_loop
                    )
                    
                    if !is_numeric!==1 if !len!==%%d (
                        set "ext=%%e"
                        set "digits=%%d"
                        call set "base=%%filename:~0,-%%d%%"
                        set "found=1"
                        goto :found
                    )
                )
            )
        )
    )
)

:found
if !found!==0 (
    echo No image sequence found in the folder.
    pause
    exit /b
)

echo Found image sequence: !base![!digits! digits].!ext!
echo.

:: Find the starting frame number
set "min_frame=99999"
for %%f in ("%folder%\!base!*.!ext!") do (
    set "filename=%%~nf"
    call set "framenum=%%filename:~-!digits!%%"
    
    :: Remove leading zeros for comparison
    set /a "num=10000000!framenum! %% 10000000"
    
    if !num! LSS !min_frame! (
        set "min_frame=!num!"
        set "start_num=!framenum!"
    )
)

echo Starting frame number: !start_num! (value: !min_frame!)

:: Check if already starts at 0
if !min_frame!==0 (
    echo Sequence already starts at 0. No renaming needed.
    pause
    exit /b
)

echo.
echo Renumbering sequence to start at 0...
echo.

:: Calculate offset
set /a "offset=!min_frame!"

:: Rename files in reverse order to avoid conflicts
:: First, collect all files and their frame numbers
set "index=0"
for %%f in ("%folder%\!base!*.!ext!") do (
    set "file[!index!]=%%f"
    set /a "index+=1"
)
set /a "total=!index!"

:: Sort and rename from highest to lowest frame number
for /L %%i in (!total!,-1,0) do (
    if defined file[%%i] (
        for %%f in ("!file[%%i]!") do (
            set "filename=%%~nf"
            call set "framenum=%%filename:~-!digits!%%"
            set /a "num=10000000!framenum! %% 10000000"
            set /a "new_num=!num! - !offset!"
            
            :: Format new frame number with leading zeros
            set "new_frame=0000000!new_num!"
            call set "new_frame=%%new_frame:~-!digits!%%"
            
            set "new_name=!base!!new_frame!.!ext!"
            
            echo Renaming: %%~nxf -^> !new_name!
            ren "%%f" "!new_name!"
        )
    )
)

echo.
echo Renumbering complete!
pause
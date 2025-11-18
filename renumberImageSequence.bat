@echo off
setlocal enabledelayedexpansion

rem =============================================================================
rem IMAGE SEQUENCE RENUMBER TOOL
rem =============================================================================
rem This script renumbers image sequences to start at frame 0
rem To use it grab the folder with your image sequence (makes sure there are not multiple image sequences in the same folder)
rem and then drag and drop that folder onto this .bat file and it will trigger the script and work on the files at the path of the folder you dragged and dropped. 
rem Supports: png, jpg, jpeg, exr, tif, tiff, dpx
rem Works with: 
rem image.##.ext
rem image.###.ext
rem image.####.ext
rem image.#####.ext
rem =============================================================================


rem Check if a folder was provided as input
if "%~1"=="" (
    echo Please drag and drop a folder onto this batch file.
    pause
    exit /b
)
rem here we check to see if the argument we got from dropping the folder on the bat file %1 leads to a directory. To do so we use the quotation marks and tilde to clean up (tilde removes quotation marks, in case there were more than two, and "" adds them back). Then the trailing backslash is added \
rem a path with a trailing backslash indicates we are look for a folder at this path (and yes the dropped folder path in the argument won't have the backslash, but to look for the folder you need the trailing backslash)
if not exist "%~1\" (
    echo The provided path is not a valid folder.
    pause
    exit /b
)
rem Change to the target folder
pushd "%~1"
echo Working in: %CD%
echo.

rem === Main Loop: === Search for image sequences > Check each extension type for potential sequences
rem Define supported image formats
echo checking images with these extensions: png jpg jpeg exr tif tiff dpx
set "ext="
set "extFound=0"
set "numDigits="


for %%e in (png jpg jpeg exr tif tiff dpx) do (
    set "ext=%%e"
    set "extFound=1"
    goto :checkForDigits
)

echo no files with those extensions found

:checkForDigits
echo found extension: !ext!

for %%f in (*.!ext!) do (
    set "filename=%%~nf"
    echo !filename!

    set "lastchars=!filename:~-5!"
    rem Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    if !errorlevel! equ 0 (
        set numDigits=5
        goto :lookForSmallestDigit
    )
    
    set "lastchars=!filename:~-4!"
    rem Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    if !errorlevel! equ 0 (
        set numDigits=4
        goto :lookForSmallestDigit
    )

    set "lastchars=!filename:~-3!"
    rem Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    if !errorlevel! equ 0 (
        set numDigits=3
        goto :lookForSmallestDigit
    )

    set "lastchars=!filename:~-2!"
    rem Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    if !errorlevel! equ 0 (
        set numDigits=2
        goto :lookForSmallestDigit
    )
)
echo Searched for frames with 2, 3, 4, or 5 digit frame numbers but could not find any. 
goto :end

:lookForSmallestDigit
echo Number of digits in frame number: !numDigits!
set "base=!filename:~0,-%numDigits%!"
echo name base is: !base!
set "minNumber="
set "lastNum=0"
set "firstIt=1"
for %%f in (!base!*) do (
    set "fname=%%~nf"
    set "lastchars=!fname:~-%numDigits%!"
    for /f "tokens=* delims=0" %%N in ("!lastchars!") do set "lastchars=%%N"
    if not defined lastchars set "lastchars=0"
    if !lastchars!==0 (
        echo Found a frame numbered zero, so assuming this sequence already starts at zero and exiting. 
        goto :end
    )
    if !firstIt! == 1 (
        set "lastnum=!lastchars!"
        set "firstIt=0"
    )
    if !lastchars! LEQ !lastNum! (
        set "minNumber=!lastchars!"
    )
    set "lastnum=!lastchars!"
)
echo The smallest frame number detected is !minNumber! and will now be frame 0
echo Setting up inputs for ffmpeg now...
:: Configuration
set "INPUT_PATTERN=!base!%%0!numDigits!d.!ext!"
set "OUTPUT_PATTERN=!base!%%0!numDigits!d.!ext!"
set "START_FRAME=!minNumber!"

echo Renumbering image sequence using ffmpeg...
echo Input pattern: %INPUT_PATTERN%
echo Output pattern: %OUTPUT_PATTERN%
echo Starting from frame: %START_FRAME%
echo.
:: Use ffmpeg to renumber the sequence
:: -start_number: where to start reading the input sequence
:: -i: input pattern (%%04d means 4-digit padding with zeros)
:: -start_number 0: output starts at 0
:: -c copy: just copy, don't re-encode
ffmpeg -start_number %START_FRAME% -i %INPUT_PATTERN% -start_number 0 -c copy %OUTPUT_PATTERN%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Success! Images have been renumbered so they start from frame 0.
    echo Output files: %OUTPUT_PATTERN%
) else (
    echo.
    echo Error occurred during renumbering.
    echo This script is using ffmpeg, if not installed this could be the issue. Otherwise something else is malfunctioning. 
)

pause
exit

:end
pause 
exit

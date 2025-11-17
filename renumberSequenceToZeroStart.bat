@echo off
setlocal enabledelayedexpansion

rem =============================================================================
rem IMAGE SEQUENCE RENUMBER TOOL
rem =============================================================================
rem This script renumbers image sequences to start at frame 0
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
pause


rem === Main Loop: === Search for image sequences > Check each extension type for potential sequences
rem Define supported image formats
echo checking images with these extensions: png jpg jpeg exr tif tiff dpx
pause
for %%e in (png jpg jpeg exr tif tiff dpx) do (
    echo %%e
    set "found=0"
    set "minframe=999999"
    set "basename="
    rem Look through all files with this extension > note this "for" syntax searches for all the files in the current directory (we changed directories above) so basically it searches for all files that match * % % e or in other words for a wildcard (*) (i.e. any filename) with extension matching e's in the current itteration of the loop. 
    for %%f in (*.%%e) do (
        echo %%f
        rem remember %~n1 is filename wihout extension and %~x1 is the extention only. That's what we are using here with out variable "f" from our argument % % f
        set "filename=%%~nf" 
        set "ext=%%~xf"
        for %%d in (5 4 3 2) do (
            echo %%d
            rem call :checkForOneMatchingImage !filename! % % d !ext!
        )
    )
)
if !found!==0 (
    echo No image sequence found in the folder.
    pause
    exit /b
)

echo got to the end
pause
exit /b


:checkForOneMatchingImage   
    set "fname=%~1"
    set "fdigits=%~2"
    set "fext=%~3"
    rem Extract the last N characters from the filename. :~ is a substring operator: variable:~start, length so we are returning the strings from start to start+length. -start means find start counting from the last character
    rem anyways this will return either the last 5, 4, 3, or 2 characters depending on digits itteration
    set "lastchars=!fname:~-%fdigits%!"
    rem Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    echo !lastchars!
    pause

    if !errorlevel! equ 0 (
        set "found=1"
        set "basename=%%fname:~0,-%fdigits%%%"
        goto :found
    )


:found
    echo Found image sequence: !base![!digits! digits].!ext!
    echo.
    pause
    exit /b
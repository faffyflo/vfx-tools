@echo off
setlocal enabledelayedexpansion

:: =============================================================================
:: IMAGE SEQUENCE RENUMBER TOOL
:: =============================================================================
:: This script renumbers image sequences to start at frame 0
:: Supports: png, jpg, jpeg, exr, tif, tiff, dpx
:: Works with: 
:: image.##.ext
:: image.###.ext
:: image.####.ext
:: image.#####.ext
:: =============================================================================

:: Check if a folder was provided as input
if "%~1"=="" (
    echo Please drag and drop a folder onto this batch file.
    pause
    exit /b
)
:: here we check to see if the argument we got from dropping the folder on the bat file %1 leads to a directory. To do so we use the quotation marks and tilde to clean up (tilde removes quotation marks, in case there were more than two, and "" adds them back). Then the trailing backslash is added \
:: a path with a trailing backslash indicates we are look for a folder at this path (and yes the dropped folder path in the argument won't have the backslash, but to look for the folder you need the trailing backslash)
if not exist "%~1\" (
    echo The provided path is not a valid folder.
    pause
    exit /b
)
:: Change to the target folder
pushd "%~1"
echo Working in: %CD%
echo.
pause


:: === Main Loop: === Search for image sequences > Check each extension type for potential sequences
:: Define supported image formats
echo checking images with these extensions: png jpg jpeg exr tif tiff dpx
pause
for %%e in (png jpg jpeg exr tif tiff dpx) do (
    echo checking %%e's
    set "found=0"
    set "minframe=999999"
    set "basename=a"
    


    :: Look through all files with this extension > note this "for" syntax searches for all the files in the current directory (we changed directories above) so basically it searches for all files that match *%%e or in other words for a wildcard (*) (i.e. any filename) with extension matching e's in the current itteration of the loop. 
    for %%f in (*.%%e) do (
        :: remember %~n1 is filename wihout extension and %~x1 is the extention only. That's what we are using here with out variable "f" from our argument %%f
        set "filename=%%~nf" 
        set "ext=%%~xf"
        set "basenameFound=False"
        echo file name: !filename!
        echo extension: !ext!
        if !basename == "True" (
            goto :next
        )
        for /L %%d in (5, -1, 2) do (
            echo %%d
            pause
            call :basename !filename! %%d !ext!
        )

    )
    pause

)

:next

:basename   
    set "fname=%~1"
    set "digits=%~2"
    set "fext=%~3"
    :: Extract the last N characters from the filename. :~ is a substring operator: variable:~start, length so we are returning the strings from start to start+length. -start means find start coundig from the last character
    :: anyways this will return either the last 5, 4, 3, or 2 characters depending on digits itteration
    set "lastchars=!fname:~-%digits%!"
    :: Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    if !errorlevel! equ 0 (
        set "frame=!lastchars!"
        echo first found frame: !frame!
        :: Convert to integer (the 10000000 trick removes leading zeros)
        set /a framenum=10000000!frame! %% 10000000
        :: Extract the base name (everything before the frame number)
        call set "base=%%fname:~0,-%digits%%%"
        echo first frame found base name to use is !base!
        :: Initialize or validate the basename
        if not defined basename (
            :: First file found - set the baseline
            set "basename=!base!"
            set "minframe=!framenum!"
            set "frameDigits=%digits%"
            set "found=1"
        ) else if "!base!"=="!basename!" (
            :: File matches current sequence - update minimum frame if needed
            if !framenum! lss !minframe! (
                set "minframe=!framenum!"
            )
        )
    )
    echo !lastchars!
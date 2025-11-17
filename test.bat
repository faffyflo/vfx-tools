:: Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
                
:: "!filename!" is the variable we made and that can change when we call :extractFrame, %%d is a constant I think so it can't change.
                @echo off
setlocal enabledelayedexpansion

:: =============================================================================
:: IMAGE SEQUENCE RENUMBER TOOL
:: =============================================================================
:: This script renumbers image sequences to start at frame 0
:: Supports: png, jpg, jpeg, exr, tif, tiff, dpx
:: Frame number formats: 2, 3, 4, or 5 digits
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
:: Change to the target directory, you need the /d flag if you are changin directories like say from C: to F:
echo Scanning folder: %~1
echo.
pause

:: === Main Loop: === Search for image sequences > Check each extension type for potential sequences
:: Define supported image formats
echo checking images with these extensions: png jpg jpeg exr tif tiff dpx
pause
for %%e in (png jpg jpeg exr tif tiff dpx) do (
    echo checking %%e's
    pause
    set "found=0"
    set "minframe=999999"
    set "basename="
    
    :: Look through all files with this extension > note this "for" syntax searches for all the files in the current directory (we changed directories above) so basically it searches for all files that match *%%e or in other words for a wildcard (*) (i.e. any filename) with extension matching e's in the current itteration of the loop. 
    for %%f in (*.%%e) do (
        echo %%f
        pause
        :: remember %~n1 is filename wihout extension and %~x1 is the extention only. That's what we are using here with out variable "f" from our argument %%f
        set "filename=%%~nf" 
        set "ext=%%~xf"
        :: for /l means loop with numbers. 5, -1, 2 means start at 5 count by -1 and stop at 2. Wecheck from 5 to 2 digits and try to extract frame numbers with that many digits from filename
        for /1 %%i in (2, 1, 5) do (
            echo %%i
            pause
            if "!basename!"=="" (
                set "fname=!filename!"
                set "digits=%%d"
                set "fext=!ext!"
                :: Extract the last N characters from the filename. :~ is a substring operator: variable:~start, length so we are returning the strings from start to start+length. -start means find start coundig from the last character
                :: anyways this will return either the last 5, 4, 3, or 2 characters depending on digits itteration
                set "lastchars=!fname:~-%digits%!"

                echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
                :: !errorlevel! is a special variable containing the exit code of the last command
                if !errorlevel! equ 0 (
                    :: Successfully found a numeric sequence
                    set "frame=!lastchars!"
                    :: Convert to integer (the 10000000 trick removes leading zeros)
                    set /a framenum=10000000!frame! %% 10000000
                    :: Extract the base name (everything before the frame number)
                    call set "base=%%fname:~0,-%digits%%%"
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
                
                

            )
        )

    )
    pause
    exit
    
    :: Process the sequence if found
    if not "!basename!"=="" (
        echo Found sequence: !basename!####!ext!
        echo Starting frame: !minframe!
        echo.
        
        :: Only renumber if sequence doesn't start at 0
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

:: If we reach here, no sequence was found
echo No image sequence found in this folder.
echo.
goto :end

:: SUBROUTINE: Extract Frame Number
:: Purpose: Attempts to extract a frame number from the end of a filename
:: Parameters:
::   %1 - Filename without extension
::   %2 - Number of digits to check (2-5)
::   %3 - File extension 
:: Sets global variables:
::   basename - The part of filename before the frame number
::   minframe - The lowest frame number found so far
::   frameDigits - Number of digits in the frame number
:extractFrame
    :: our 3 arguments from earlier, so fname is storing filename, digits is storing 5,4,3,2 and fext is storing the extension
    set "fname=%~1"
    set "digits=%~2"
    set "fext=%~3"
    :: Extract the last N characters from the filename. :~ is a substring operator: variable:~start, length so we are returning the strings from start to start+length. -start means find start coundig from the last character
    :: anyways this will return either the last 5, 4, 3, or 2 characters depending on digits itteration
    set "lastchars=!fname:~-%digits%!"
    :: Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
    echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
    :: !errorlevel! is a special variable containing the exit code of the last command
    if !errorlevel! equ 0 (
        :: Successfully found a numeric sequence
        set "frame=!lastchars!"
        :: Convert to integer (the 10000000 trick removes leading zeros)
        set /a framenum=10000000!frame! %% 10000000
        :: Extract the base name (everything before the frame number)
        call set "base=%%fname:~0,-%digits%%%"
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
    exit /b

:: SUBROUTINE: Renumber Sequence
:: Purpose: Renumbers all files in a sequence to start at frame 0
:: Parameters:
::   %1 - Base filename (before frame number)
::   %2 - File extension
::   %3 - Offset to subtract (the original starting frame number)
:: 
:: Process:
::   1. Collect all files and calculate new names
::   2. Rename to temporary names (avoids collisions)
::   3. Remove temp prefix to finalize names
:renumberSequence
    set "base=%~1"
    set "ext=%~2"
    set "offset=%~3"
    
    :: Create a temporary file to store the rename operations
    set "tempfile=%temp%\rename_list_%random%.txt"
    
    :: PASS 1: Collect all files and calculate new frame numbers
    for %%f in (%base%*%ext%) do (
        set "filename=%%~nf"
        
        :: Try to extract the frame number (check 5 down to 2 digits)
        for /l %%d in (5,-1,2) do (
            set "lastchars=!filename:~-%%d!"
            
            :: Verify the extracted characters are numeric
            echo !lastchars!| findstr /r "^[0-9][0-9]*$" >nul
            if !errorlevel! equ 0 (
                :: Convert frame number to integer
                set /a oldframe=10000000!lastchars! %% 10000000
                
                :: Calculate new frame number (subtract offset)
                set /a newframe=!oldframe!-%offset%
                
                :: Pad the new frame number with leading zeros
                set "padded=0000!newframe!"
                set "padded=!padded:~-%%d!"
                
                :: Store the old and new filenames in temp file
                echo %%f|%base%!padded!%ext% >> "!tempfile!"
                goto :nextFile
            )
        )
        :nextFile
    )
    
    :: PASS 2: Rename to temporary names
    :: This prevents collisions when frame numbers overlap
    :: Example: renaming 0005->0004 while 0004 exists would fail
    :: So we rename to temp_0004 first, then remove the prefix
    for /f "tokens=1,2 delims=|" %%a in (!tempfile!) do (
        ren "%%a" "temp_%%b"
    )
    
    :: PASS 3: Remove temporary prefix to finalize names. Note when renaming if you don't specify an extension in the desination then Windows keeps the original extension. 
    ren "temp_%base%*%ext%" "%base%*"
    
    :: Clean up temporary file
    del "!tempfile!"
    exit /b

:: =============================================================================
:: End of script
:: =============================================================================
:end
pause
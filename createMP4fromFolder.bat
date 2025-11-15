@echo off
REM @echo off means don't show each command as it runs, only show the output we want


REM ========================================
REM Image Sequence to MP4 Converter
REM ========================================
REM Usage: Drag and drop a folder containing image sequences onto this .bat file
REM Supports: 2, 3, 4, or 5 digit padding (e.g., render_01.png, shot_001.jpg, frame_1200.tif)
REM Supports: png, jpg, jpeg, tif, tiff, exr, dpx
REM ========================================


REM === STEP 1: Get folder and navigate to it ===
REM %~1 is a special variable that holds the first thing dragged onto this bat file
if "%~1"=="" (
    REM If nothing was dragged, %~1 will be empty ("")
    echo Please drag a folder containing image sequences onto this batch file.
    REM pause keeps the window open so user can read the message
    pause
    REM exit /b means stop running the script and close the current window, but won't close the window it was called from if it was called from another script. It's just good practice to do it this way in case it were. 
    exit /b
)
REM "set" creates a variable (like a container to store information)
set "folder=%~1"
REM cd means "change directory" (move to a different folder) and /d allows us to change to a folder on a different drive (like D: or E:)
cd /d "%folder%"
REM "%folder%" uses the path we stored earlier


REM === STEP 2: Find the first image file ===
REM Create empty variables to store what we find
set "firstfile="
set "ext="
REM for loop, variable e will be one of the listed file extensions in each iteration
for %%e in (png jpg jpeg tif tiff exr dpx) do (
    REM "if not defined" means "if this variable is still empty", once we find something we will set firstfile to it and then it will not be empty and we will skip past
    if not defined firstfile (
        REM This inner "for" loop searches for files with the current extension
        REM 'dir /b /o:n *.%%e' will list the files that match *.%%e so anything that is like anyName.png if %%e is currently iterating as png
        REM   dir = list files > the files will get listed, kind of like we listed our file formats above, and then we will itterate through each
        REM   /b = bare format (just filenames, no dates or sizes)
        REM   /o:n = order by name (sort alphabetically/numerically)
        REM   2^>nul = hide error messages if no files found (we're doing a lot of checks potentially for each file type so we'd get a lot of "file not found" errors, so we suppress that)
        REM  "delims=" sets the delimeters to use to break up the string returned, if we don't put anything after the equals sign we are saying use NO delimters. So my file.png for example wouldn't be split into my and file and png or whatever
        for /f "delims=" %%f in ('dir /b /o:n *.%%e 2^>nul') do (
            REM We found a file! Store its name and extension
            set "firstfile=%%f"
            set "ext=%%e"
            REM goto jumps to a label (like skipping ahead in the script)
            goto :found
        )
    )
)


REM === STEP 3: Check if we found any images ===
REM we jump to :found from another goto above
:found
REM If firstfile is still empty, we didn't find any supported images
if not defined firstfile (
    echo No supported image files found in the folder.
    echo Supported formats: png, jpg, jpeg, tif, tiff, exr, dpx
    pause
    exit /b
)


REM === STEP 4: Calculate extension length ===
REM We need to know how many characters the extension is - For example: ".png" = 4 characters (the dot plus p, n, g)
set "extlen=0"
set "tempext=%ext%"
REM note %ext% variable was defined in our for loop that was searching for a matching file
REM :countloop is another label for a counting loop, it's a work around because there is now way to count a string length I guess. So this is a way to get the extension length and then set it to a variable
:countloop
REM if tempext is NOT empty, keep going
if not "%tempext%"=="" (
    REM Add 1 to our counter
    REM /a means "do arithmetic (math)"
    set /a extlen+=1
    REM Remove the first character from tempext
    REM :~1 means "everything starting from position 1" (skipping position 0)
    set "tempext=%tempext:~1%"
    REM Go back and count again until the variable is empty
    goto :countloop
)
REM Add 1 more for the dot (.) at the beginning
set /a extlen+=1


REM === STEP 5: Remove extension from filename ===
REM call allows us to use variables inside other variables
REM :~0,-%extlen% means "from position 0, remove the last extlen characters"
REM So if extlen=4, this removes the last 4 characters (.png)
call set "filename=%%firstfile:~0,-%extlen%%%"

REM === STEP 6: Detect padding length (2, 3, 4, or 5 digits) ===
set "padding=0"
set "startnum="
REM We'll check from longest to shortest (5, 4, 3, 2) - This prevents mistaking "01234" (5 digits) for "1234" (4 digits)

REM --- Try 5 digits first ---
REM :~-5 means "the last 5 characters"
set "test5=%filename:~-5%"
REM Assume it's a number until proven otherwise
set "isnum5=1"
REM This trick checks if test5 contains ONLY digits (0-9)
REM "for /f delims=0123456789" means "split by any digit"
REM If test5 is all digits, there's nothing to split, so this doesn't run
REM If test5 has letters, %%a will contain them, setting isnum5=0
for /f "delims=0123456789" %%a in ("%test5%") do set "isnum5=0"
REM If isnum5 is still 1 (true) and test5 isn't empty
if "%isnum5%"=="1" if not "%test5%"=="" (
    REM We found 5-digit padding!
    set "padding=5"
    set "startnum=%test5%"
    REM Skip the other checks
    goto :padding_found
)

REM --- Try 4 digits ---
set "test4=%filename:~-4%"
set "isnum4=1"
for /f "delims=0123456789" %%a in ("%test4%") do set "isnum4=0"
if "%isnum4%"=="1" if not "%test4%"=="" (
    set "padding=4"
    set "startnum=%test4%"
    goto :padding_found
)

REM --- Try 3 digits ---
set "test3=%filename:~-3%"
set "isnum3=1"
for /f "delims=0123456789" %%a in ("%test3%") do set "isnum3=0"
if "%isnum3%"=="1" if not "%test3%"=="" (
    set "padding=3"
    set "startnum=%test3%"
    goto :padding_found
)

REM --- Try 2 digits ---
set "test2=%filename:~-2%"
set "isnum2=1"
for /f "delims=0123456789" %%a in ("%test2%") do set "isnum2=0"
if "%isnum2%"=="1" if not "%test2%"=="" (
    set "padding=2"
    set "startnum=%test2%"
    goto :padding_found
)

REM If we get here, we couldn't detect the padding
REM This means the filename doesn't end with 2-5 digits
echo Could not detect frame number padding.
echo Please ensure filenames end with 2, 3, 4, or 5 digit frame numbers.
echo Example: render_001.png or shot_1200.jpg
pause
exit /b

REM === STEP 7: Extract the base name ===
:padding_found
REM Get the folder name to use in the output filename
REM %%~na is special syntax that extracts just the folder name
REM For example: "C:\Users\Me\MyProject" becomes "MyProject"
for %%a in ("%folder%") do set "foldername=%%~na"
REM note I don't think we need foldername afterall, but just leaving it in for now
REM Get the base name by removing the frame number digits
REM For example: "render_1200" with padding=4 becomes "render_"
REM :~0,-%padding% means "from start, remove the last 'padding' characters"
call set "basename=%%filename:~0,-%padding%%%"

REM === STEP 8: Run ffmpeg to create the video ===REM Display information so the user knows what's happening
REM %%0%padding%d is ffmpeg notation for padded numbers
REM For example: %%04d means 4 digits with leading zeros (0001, 0002, etc.)
echo Converting: %basename%%%0%padding%d.%ext%
echo Start frame: %startnum%
echo Padding: %padding% digits
echo Output: %foldername%_output.mp4
echo.

ffmpeg -start_number %startnum% -i "%basename%%%0%padding%d.%ext%" -c:v libx264 -pix_fmt yuv420p -crf 18 -r 24 "%basename%_output.mp4"

REM Print a blank line for spacing
echo.
REM Keep the window open so user can see if it worked
pause
exit /b



REM Some helpful comments for....

REM FFMPEG
REM ffmpeg is a separate program that does the actual conversion
REM Here's what each parameter means:
REM 
REM -start_number %startnum%
REM   Tells ffmpeg which frame number to start from
REM   For example: if your first file is render_1200.png, this is 1200
REM
REM -i "%basename%%%0%padding%d.%ext%"
REM   The input pattern - tells ffmpeg how to find your images
REM   %%0%padding%d is a placeholder for the frame numbers
REM   For example: render_%%04d.png means render_0001.png, render_0002.png, etc.
REM
REM -c:v libx264
REM   The video codec (compression method) to use
REM   libx264 creates H.264 video, which plays almost everywhere
REM
REM -pix_fmt yuv420p
REM   The pixel format - how colors are stored
REM   yuv420p is compatible with most video players
REM
REM -crf 18
REM   The quality level (0-51, lower = better quality)
REM   18 is very high quality
REM   23 is default, 0 is lossless (huge files)
REM
REM -r 24
REM   Frame rate - how many frames per second
REM   24 fps is standard for film
REM
REM "%foldername%_output.mp4"
REM   The output filename
REM   Uses the folder name + "_output.mp4"



REM ========================================
REM UNDERSTANDING THE % SYMBOL IN BATCH FILES
REM ========================================
REM The % symbol has different meanings depending on context:
REM
REM 1. VARIABLES - %variablename%
REM    Example: %folder% means "the value stored in the variable called folder"
REM    The % symbols tell the computer "this is a variable, get its value"
REM
REM 2. COMMAND LINE ARGUMENTS - %1, %2, %3, etc.
REM    %1 = first thing passed to the script (in our case, the dragged folder)
REM    %~1 = same as %1 but removes quotes if they exist
REM    %0 = the name of the batch file itself
REM
REM 3. FOR LOOP VARIABLES - %%a, %%e, %%f, etc.
REM    In for loops, you use TWO percent signs (%%a not %a)
REM    This is because batch files use %a for something else
REM    Example: for %%e in (png jpg) do echo %%e
REM
REM 4. ESCAPING % - %%%%
REM    If you want to display an actual % symbol, you need %%
REM    Example: "50%%" displays as "50%"
REM
REM 5. SPECIAL MODIFIERS - %~na, %~1, etc.
REM    %~na = just the name of a file (no path, no extension)
REM    %~1 = remove quotes from argument 1
REM    These are shortcuts for common operations
REM
REM Examples you'll see in this script:
REM   %~1 = the dragged folder path (quotes removed)
REM   %folder% = the value in the "folder" variable
REM   %%e = the loop variable (current file extension being checked)
REM   %%~na = just the name part of a file
REM   %%04d = this is for ffmpeg (not batch!), means 4-digit padding
REM ========================================


REM ========================================
REM UNDERSTANDING FOR LOOPS IN BATCH FILES
REM ========================================
REM There are different types of "for" loops:
REM
REM 1. BASIC FOR LOOP - for %%x in (list) do command
REM    Loops through a simple list of items
REM    Example: for %%e in (png jpg tif) do echo %%e
REM    This just goes through: png, then jpg, then tif
REM
REM    IMPORTANT: In the parentheses (png jpg tif), these ARE strings/text!
REM    Batch files don't have fancy data types like "string" vs "number"
REM    Everything is just text, separated by spaces
REM    So (png jpg tif) is a list of three text items: "png", "jpg", "tif"
REM    You don't need quotes around them unless they have spaces
REM    Example: (png jpg tif) works fine
REM    Example: ("my file.txt" "other file.doc") needs quotes because of spaces
REM
REM 2. FOR /F LOOP - for /f "options" %%x in (source) do command
REM    The /F means "FILE processing" or "parse text/command output"
REM    This is MORE POWERFUL - it can:
REM      - Read output from commands (like dir)
REM      - Parse text files line by line
REM      - Split lines into pieces
REM    
REM    In this script we use: for /f "delims=" %%f in ('dir /b /o:n *.png') do...
REM    Breaking this down:
REM      - for /f = use file/text processing mode
REM      - "delims=" = don't split the line into parts (keep whole filenames)
REM      - %%f = the variable to store each line
REM      - ('dir /b /o:n *.png') = run this command and process its output
REM      - The single quotes 'command' mean "run this and give me the output"
REM    
REM    So this loop runs "dir /b /o:n *.png" (list PNG files), 
REM    then loops through each filename in the output.
REM
REM 3. FOR /D LOOP - for /d %%x in (pattern) do command
REM    Loops through directories only (not files)
REM
REM 4. FOR /R LOOP - for /r %%x in (pattern) do command  
REM    Recursively loops through subdirectories
REM
REM WHY USE FOR /F IN THIS SCRIPT?
REM We need to run the "dir" command to list files, then process each filename.
REM A basic "for" loop can't do this - it only works with simple lists.
REM For /f lets us capture command output and loop through it line by line.
REM ========================================
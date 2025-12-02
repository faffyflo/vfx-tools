@echo off
setlocal enabledelayedexpansion

REM Check if a folder was dropped
if "%~1"=="" (
    echo Please drag and drop a folder onto this batch file.
    pause
    exit /b
)

REM Check if the dropped item is a directory
if not exist "%~1\*" (
    echo The dropped item is not a valid folder.
    pause
    exit /b
)

set "input_folder=%~1"
set "output_file=%~1\output.mp4"

echo Processing folder: %input_folder%
echo.

REM Check if FFmpeg is available
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: FFmpeg is not installed or not in PATH.
    echo Please install FFmpeg from https://ffmpeg.org/download.html
    pause
    exit /b
)

REM Count PNG files
set count=0
for %%f in ("%input_folder%\*.png") do set /a count+=1

if %count%==0 (
    echo No PNG files found in the folder.
    pause
    exit /b
)

echo Found %count% PNG files.
echo Creating video...
echo.

REM Create a file list for FFmpeg in the input folder
set "filelist=%input_folder%\ffmpeg_filelist.txt"
if exist "%filelist%" del "%filelist%"

echo Creating file list...
cd /d "%input_folder%"
for %%f in ("*.png") do (
    echo file '%%f' >> ffmpeg_filelist.txt
    echo duration 1 >> ffmpeg_filelist.txt
)
REM Add the last file again without duration (FFmpeg requirement)
for %%f in ("*.png") do (
    echo file '%%f' >> ffmpeg_filelist.txt
    goto :break
)
:break

REM Create the video using FFmpeg
REM -f concat uses the concat demuxer to read from file list
REM -safe 0 allows absolute paths
REM -r 1 means 1 frame per second (adjust as needed)
REM -vf scale ensures dimensions are divisible by 2 (required for libx264)
REM -c:v libx264 uses H.264 codec
REM -pix_fmt yuv420p ensures compatibility with most players

ffmpeg -f concat -safe 0 -i "ffmpeg_filelist.txt" -r 1 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p -y "output.mp4"

REM Clean up temp file
del "ffmpeg_filelist.txt"

if %errorlevel%==0 (
    echo.
    echo SUCCESS! Video created: %output_file%
) else (
    echo.
    echo ERROR: Video creation failed.
)

echo.
pause
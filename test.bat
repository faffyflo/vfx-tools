:: Check if these characters are all numeric digits. Note finstr expects to search within text input, so we need to echo (print/output) lastchar and then pipe that output "|" to finstr
                
:: "!filename!" is the variable we made and that can change when we call :extractFrame, %%d is a constant I think so it can't change.
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
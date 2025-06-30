@echo off
setlocal enabledelayedexpansion

rem make output file compliant with batch file naming conventions 

rem Initialize the weekend_or_weekday variable
set "weekend_or_weekday="

rem Get the current date in the format YYYYMMDDHHMMSS using PowerShell
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set datetime=%%a

rem Extract the date components
set year=%datetime:~0,4%
set month=%datetime:~4,2%
set day=%datetime:~6,2%

rem Format the date as MMDDYY
set formattedDate=%month%%day%%year%

:: Adjust month and year for Zeller's Congruence
if %month% lss 3 (
    set /a month=%month% + 12
    set /a year=%year% - 1
)

:: Extract century and year of the century
set /a K=%year% %% 100
set /a J=%year% / 100

:: Zeller's Congruence formula to calculate the day of the week
set /a f=%day% + (13 * (%month% + 1) / 5) + %K% + (%K% / 4) + (%J% / 4) - (2 * %J%)
set /a f=(f %% 7 + 7) %% 7

:: Map the result to the day of the week
set dayName=
for %%i in (Saturday Sunday Monday Tuesday Wednesday Thursday Friday) do (
    if !f! equ 0 (
        set dayName=%%i
    )
    set /a f=!f! - 1
)

rem Check if the day of the week starts with 'S' (Saturday or Sunday)
if /i "!dayName:~0,1!"=="S" (
    set "weekend_or_weekday=weekend"
) else (
    set "weekend_or_weekday=weekday"
)

set "outputFilePath=HS_%formattedDate%_!weekend_or_weekday!.bat"

rem Following code is to set the output file path to one directory above the current one
rem set "outputFilePath=..\HS_%formattedDate%_!weekend_or_weekday!.bat"

rem Display the result
echo BATCH NAME: %outputFilePath%

set "filePath=.\input.txt"

rem ask user if they want to add calibration scripts

set /p add_phase="Would you like to automatically add calibration to your scripts? (y/n) "

if /i "%add_phase%"=="y" (
    echo Adding calibration scripts...
	echo:
) else if /i "%add_phase%"=="n" (
    echo NO calibration scripts...
	echo:
) else (
    echo Invalid input exiting script...
    exit /b
)

echo Continuing with the rest of the script...
echo: 

REM Check if the file exists
if exist "%filePath%" (
    echo The file exists. Processing contents...

    REM Ensure the output file is completely cleared (no blank first line)
	if exist "%outputFilePath%" del "%outputFilePath%"

    REM Read and process the contents of the file line by line assuming it is formatted like so: R15 M and P AUTO or R15 P OFF
    for /f "delims=" %%a in (%filePath%) do (
        set "line=%%a"
        set "phase=D:\QA_Tools\Automation\Modules\ScenarioTests\Calibration\Phase\calibration.txt"
        echo Processing line: !line!
		
		set "noSpaces=!line: =!"
		
		
        
rem		echo !line! | find " " >nul
		
        if not "!line!"=="!noSpaces!" (
		
			>> "%outputFilePath%" echo # !line!
		
			if /i "%add_phase%"=="y" (
				>> "%outputFilePath%" echo !phase!
			)

            REM The line contains a space
            set "output=D:\QA_Tools\Automation\Modules\ScenarioTests\Traj\FQT\"
			set "second_output=D:\QA_Tools\Automation\Modules\ScenarioTests\Traj\FQT\"
            set "text_file="

            REM Initialize the index
            set "index=0"

            REM Loop through each word in the string
            for %%b in (!line!) do (
                set /a index+=1
                set "array[!index!]=%%b"
            )

            REM Get correct scenario folder
            set "scenario=!array[1]!\Jam\"
			
            REM Add on end part (txt files)
            if "!index!"=="3" (
                set "text_file=!array[1]!_jam_!array[2]!_NA_!array[3]!.txt"
                set "output=!output!!scenario!!text_file!"
                >> "%outputFilePath%" echo !output!
				echo. >> "%outputFilePath%"
            ) else (
                REM Do code type first depending on order
                set "text_file=!array[1]!_jam_!array[2]!_NA_!array[5]!.txt"
                set "output=!output!!scenario!!text_file!"
                >> "%outputFilePath%" echo !output!
                if /i "%add_phase%"=="y" (
					>> "%outputFilePath%" echo !phase!
				)
				
                REM Do M or P second depending on order
                set "text_file=!array[1]!_jam_!array[4]!_NA_!array[5]!.txt"
                set "output=!second_output!!scenario!!text_file!"
                >> "%outputFilePath%" echo !output!
				echo. >> "%outputFilePath%"
            )
        ) else (
			
			
            REM The line does not contain a space 
           
			set "no_space_output=D:\QA_Tools\Automation\Modules\ScenarioTests\Traj\FQT\"
            set "no_space_text_file=!line!.txt"
			
			rem Replace the delimiter with something unique
			set "marked_line=!line:_jam_=<!"
			set "fully_marked_line=!marked_line:_type_=<!"

			rem Get the part BEFORE the <
			for /f "tokens=1 delims=<" %%a in ("!marked_line!") do (
			
				set "no_space_scenario=%%a\Jam\"
			)

			for /f "tokens=1 delims=\" %%b in ("!no_space_scenario!") do (
			
				set "scenario_part=%%b"
			)
			
			set "scenario_part=!scenario_part:_= !"
			
			rem WORK ONNNN
			for /f "tokens=2 delims=<" %%d in ("!fully_marked_line!") do (
			
				set "code_type=%%d"
			)
			
			for /f "tokens=3 delims=<" %%f in ("!fully_marked_line!") do (
			
				set "run_type=%%f"
			)
			
			set comment_line=!scenario_part! !code_type! !run_type!
		
			set "no_space_output=!no_space_output!!no_space_scenario!!no_space_text_file!"
			
			>> "%outputFilePath%" echo # !comment_line!
		
			if /i "%add_phase%"=="y" (
				>> "%outputFilePath%" echo !phase!
			)
			>> "%outputFilePath%" echo !no_space_output!
			echo. >> "%outputFilePath%"
        )
    )
	
	echo: 
	echo:
	
	rem check if paths in output exist or not
	rem Loop through each line in the output file, using usebackq for quoted file path
	for /f "usebackq delims=" %%f in ("%outputFilePath%") do (
		rem Check if the line contains a backslash
		echo %%f | findstr /c:"\\" >nul
		if not errorlevel 1 (
			rem Assign the current line to the script_paths variable
			set "script_paths=%%f"
			
			rem Use delayed expansion to check if the path exists
			if not exist "!script_paths!" (
				
				echo "!script_paths! is a path that DOES NOT EXIST"
			)
		)
	)
	
) else (
    echo The file does not exist. Please check the path and try again.
)

endlocal
pause

@echo off
REM Run payload generator with any parameters passed to this script
payloadGen.exe %*

:: After execution, optionally rename generated .bin files interactively
setlocal EnableDelayedExpansion

echo.
echo Select file to rename:
set /a idx=0
for %%F in (*.bin) do (
    set /a idx+=1
    set "file[!idx!]=%%F"
    echo !idx!. %%F
)

if !idx! EQU 0 (
    echo No .bin files found.
    goto :eof
)

echo 0. Rename ALL files
set /p choice=Enter number (0 for all): 

if "%choice%"=="0" goto rename_all
if defined file[%choice%] (
    set "selected=!file[%choice%]!"
    goto rename_one
)

echo Invalid selection.
goto :eof

:rename_one
powershell -NoProfile -Command "$file = '%selected%'; $n=$file -replace ' ', '_' -replace '[\[\]\(\)]', ''; if($n -ne $file) { Rename-Item -LiteralPath $file -NewName $n }"
echo Done.
goto :eof

:rename_all
powershell -NoProfile -Command "Get-ChildItem -Filter '*.bin' | ForEach-Object { $n=$_.Name -replace ' ', '_' -replace '[\[\]\(\)]', ''; if($n -ne $_.Name) { Rename-Item -LiteralPath $_.FullName -NewName $n } }"
echo Done.
goto :eof 
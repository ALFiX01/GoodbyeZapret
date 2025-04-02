@echo off
setlocal enabledelayedexpansion
REM Устанавливаем кодировку консоли на UTF-8 (может помочь с отображением)
chcp 65001 > nul

echo Starting domain availability check...
echo =====================================
echo.

REM --- Define Domain Lists ---
set DISCORD_DOMAINS=^
discord.com ^
discord.co ^
discord.app ^
discord.gg ^
discord.dev ^
discord.new ^
discord.gift ^
discordapp.com ^
discordapp.io ^
discordapp.net ^
discordcdn.com ^
discordstatus.com ^
discord.media ^
dis.gd ^
discord-attachments-uploads-prd.storage.googleapis.com

set YOUTUBE_OTHER_DOMAINS=^
youtube.com ^
googlevideo.com ^
ggpht.com ^
ytimg.com ^
yt.be ^
youtu.be ^
googleadservices.com ^
gvt1.com ^
youtube-nocookie.com ^
youtube-ui.l.google.com ^
youtubeembeddedplayer.googleapis.com ^
youtube.googleapis.com ^
youtubei.googleapis.com ^
jnn-pa.googleapis.com ^
yt-video-upload.l.google.com ^
wide-youtube.l.google.com ^
play.google.com ^
accounts.google.com ^
youtubekids.com ^
7tv.app ^
7tv.io ^
10tv.app

REM --- Initialize Overall Counters ---
set OK_OVERALL=0
set FAILED_OVERALL=0
set TOTAL_OVERALL=0

REM ====================================
REM === Process Discord Group        ===
REM ====================================
echo === Checking DISCORD Domains ===
set OK_GROUP=0
set FAILED_GROUP=0
set TOTAL_GROUP=0
set GROUP_NAME=Discord
for %%D in (!DISCORD_DOMAINS!) do (
    set /a TOTAL_GROUP+=1
    set /a TOTAL_OVERALL+=1
    echo Checking %%D... ^(!GROUP_NAME! Group - Item !TOTAL_GROUP!^)
    ping -n 1 -w 1000 %%D
    if errorlevel 1 (
        echo   ---> Status for %%D: FAILED
        set /a FAILED_GROUP+=1
        set /a FAILED_OVERALL+=1
    ) else (
        echo   ---> Status for %%D: OK
        set /a OK_GROUP+=1
        set /a OK_OVERALL+=1
    )
    echo -------------------------------------
    echo.
)
echo === !GROUP_NAME! Group Statistics ===
echo   Total checked: !TOTAL_GROUP!
echo   Reachable:     !OK_GROUP!
echo   Failed:        !FAILED_GROUP!
echo =====================================
echo.
echo.

REM ====================================
REM === Process YouTube/Other Group  ===
REM ====================================
echo === Checking YouTube/Other Domains ===
set OK_GROUP=0  REM Reset group counters
set FAILED_GROUP=0
set TOTAL_GROUP=0
set GROUP_NAME=YouTube/Other
for %%D in (!YOUTUBE_OTHER_DOMAINS!) do (
    set /a TOTAL_GROUP+=1
    set /a TOTAL_OVERALL+=1
    echo Checking %%D... ^(!GROUP_NAME! Group - Item !TOTAL_GROUP!^)
    ping -n 1 -w 1000 %%D
    if errorlevel 1 (
        echo   ---> Status for %%D: FAILED
        set /a FAILED_GROUP+=1
        set /a FAILED_OVERALL+=1
    ) else (
        echo   ---> Status for %%D: OK
        set /a OK_GROUP+=1
        set /a OK_OVERALL+=1
    )
    echo -------------------------------------
    echo.
)
echo === !GROUP_NAME! Group Statistics ===
echo   Total checked: !TOTAL_GROUP!
echo   Reachable:     !OK_GROUP!
echo   Failed:        !FAILED_GROUP!
echo =====================================
echo.
echo.


REM ====================================
REM === Final Overall Statistics     ===
REM ====================================
echo =====================================
echo Check finished. Overall Statistics:
echo   Total domains checked: !TOTAL_OVERALL!
echo   Total reachable:       !OK_OVERALL!
echo   Total failed:          !FAILED_OVERALL!
echo =====================================
echo.

endlocal
pause REM Оставляем окно открытым, чтобы увидеть результаты
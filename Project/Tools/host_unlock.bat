@echo off
setlocal enabledelayedexpansion

set "hostspath=%SystemRoot%\System32\drivers\etc\hosts"
set "tempfile=%temp%\hosts.tmp"

:menu
cls
echo Current status:
findstr /c:"0.0.0.0 www.aomeitech.com" "%hostspath%" >nul
if not errorlevel 1 (
    powershell -Command "Write-Host 'Entries are present in hosts file' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'No entries found in hosts file' -ForegroundColor Red"
)
echo.
echo  1. Add entries
echo  2. Remove entries
choice /c 12 /n /m " Select an option (1 or 2): "
if errorlevel 2 goto remove
if errorlevel 1 goto add

:add
findstr /c:"0.0.0.0 www.aomeitech.com" "%hostspath%" >nul
if not errorlevel 1 (
    echo  Entries already exist.
    timeout /t 3
    goto :eof
)

(
echo 0.0.0.0 www.aomeitech.com
echo 3.66.189.153 mail.proton.me
echo 31.13.72.36 facebook.com
echo 31.13.72.36 www.facebook.com
echo 31.13.72.12 static.xx.fbcdn.net
echo 31.13.72.12 external-hel3-1.xx.fbcdn.net
echo 157.240.225.174 www.instagram.com
echo 157.240.225.174 instagram.com
echo 157.240.247.63 scontent.cdninstagram.com
echo 157.240.247.63 scontent-hel3-1.cdninstagram.com
echo 157.240.245.174 b.i.instagram.com
echo 157.240.245.174 z-p42-chat-e2ee-ig.facebook.com
echo 3.66.189.153 protonmail.com
echo 204.12.192.222 chatgpt.com
echo 204.12.192.222 ab.chatgpt.com
echo 204.12.192.222 auth.openai.com
echo 204.12.192.222 auth0.openai.com
echo 204.12.192.222 platform.openai.com
echo 204.12.192.222 cdn.oaistatic.com
echo 204.12.192.222 files.oaiusercontent.com
echo 204.12.192.222 cdn.auth0.com
echo 204.12.192.222 tcr9i.chat.openai.com
echo 204.12.192.222 webrtc.chatgpt.com
echo 204.12.192.222 android.chat.openai.com
echo 204.12.192.222 api.openai.com
echo 138.201.204.218 gemini.google.com
echo 204.12.192.222 aistudio.google.com
echo 204.12.192.222 generativelanguage.googleapis.com
echo 204.12.192.222 alkalimakersuite-pa.clients6.google.com
echo 204.12.192.222 aitestkitchen.withgoogle.com
echo 204.12.192.222 aisandbox-pa.googleapis.com
echo 204.12.192.222 webchannel-alkalimakersuite-pa.clients6.google.com
echo 204.12.192.222 proactivebackend-pa.googleapis.com
echo 204.12.192.222 o.pki.goog
echo 204.12.192.222 labs.google
echo 204.12.192.222 notebooklm.google
echo 204.12.192.222 notebooklm.google.com
echo 204.12.192.222 copilot.microsoft.com
echo 204.12.192.222 www.bing.com
echo 204.12.192.222 sydney.bing.com
echo 204.12.192.222 edgeservices.bing.com
echo 50.7.85.221 rewards.bing.com
echo 204.12.192.222 xsts.auth.xboxlive.com
echo 204.12.192.222 api.spotify.com
echo 204.12.192.222 xpui.app.spotify.com
echo 204.12.192.222 appresolve.spotify.com
echo 204.12.192.222 login5.spotify.com
echo 204.12.192.222 gew1-spclient.spotify.com
echo 204.12.192.222 gew1-dealer.spotify.com
echo 204.12.192.222 spclient.wg.spotify.com
echo 204.12.192.222 api-partner.spotify.com
echo 204.12.192.222 aet.spotify.com
echo 204.12.192.222 www.spotify.com
echo 204.12.192.222 accounts.spotify.com
echo 204.12.192.222 spotifycdn.com
echo 204.12.192.222 open-exp.spotifycdn.com
echo 204.12.192.222 www-growth.scdn.co
echo 204.12.192.222 o22381.ingest.sentry.io
echo 50.7.87.84 login.app.spotify.com
echo 138.201.204.218 encore.scdn.co
echo 204.12.192.222 accounts.scdn.co
echo 138.201.204.218 ap-gew1.spotify.com
echo 94.131.119.85 www.notion.so
echo 50.7.85.222 www.canva.com
echo 204.12.192.222 www.intel.com
echo 204.12.192.219 www.dell.com
echo 204.12.192.220 developer.nvidia.com
echo 50.7.87.85 codeium.com
echo 50.7.85.219 inference.codeium.com
echo 50.7.85.219 www.tiktok.com
echo 50.7.87.84 api.github.com
echo 50.7.85.221 datalore.jetbrains.com
echo 107.150.34.100 plugins.jetbrains.com
echo 204.12.192.222 elevenlabs.io
echo 204.12.192.222 api.us.elevenlabs.io
echo 204.12.192.222 elevenreader.io
echo 204.12.192.221 truthsocial.com
echo 204.12.192.221 static-assets-1.truthsocial.com
echo 185.250.151.49 grok.com
echo 185.250.151.49 accounts.x.ai
echo 94.131.119.85 autodesk.com
echo 94.131.119.85 accounts.autodesk.com
echo 204.12.192.222 claude.ai
echo 0.0.0.0 only-fans.uk
echo 0.0.0.0 only-fans.me
echo 0.0.0.0 only-fans.wtf
) >> "%hostspath%"
powershell -Command "Write-Host 'Entries added successfully.' -ForegroundColor Green"
timeout /t 3
goto :eof

:remove
type nul > "%tempfile%"
for /f "tokens=*" %%a in ('type "%hostspath%"') do (
    echo %%a | findstr /i /c:"www.aomeitech.com" /c:"mail.proton.me" /c:"facebook.com" /c:"www.facebook.com" /c:"static.xx.fbcdn.net" /c:"external-hel3-1.xx.fbcdn.net" /c:"www.instagram.com" /c:"instagram.com" /c:"scontent.cdninstagram.com" /c:"scontent-hel3-1.cdninstagram.com" /c:"b.i.instagram.com" /c:"z-p42-chat-e2ee-ig.facebook.com" /c:"protonmail.com" /c:"chatgpt.com" /c:"ab.chatgpt.com" /c:"auth.openai.com" /c:"auth0.openai.com" /c:"platform.openai.com" /c:"cdn.oaistatic.com" /c:"files.oaiusercontent.com" /c:"cdn.auth0.com" /c:"tcr9i.chat.openai.com" /c:"webrtc.chatgpt.com" /c:"android.chat.openai.com" /c:"api.openai.com" /c:"gemini.google.com" /c:"aistudio.google.com" /c:"generativelanguage.googleapis.com" /c:"alkalimakersuite-pa.clients6.google.com" /c:"aitestkitchen.withgoogle.com" /c:"aisandbox-pa.googleapis.com" /c:"webchannel-alkalimakersuite-pa.clients6.google.com" /c:"proactivebackend-pa.googleapis.com" /c:"o.pki.goog" /c:"labs.google" /c:"notebooklm.google" /c:"notebooklm.google.com" /c:"copilot.microsoft.com" /c:"www.bing.com" /c:"sydney.bing.com" /c:"edgeservices.bing.com" /c:"rewards.bing.com" /c:"xsts.auth.xboxlive.com" /c:"api.spotify.com" /c:"xpui.app.spotify.com" /c:"appresolve.spotify.com" /c:"login5.spotify.com" /c:"gew1-spclient.spotify.com" /c:"gew1-dealer.spotify.com" /c:"spclient.wg.spotify.com" /c:"api-partner.spotify.com" /c:"aet.spotify.com" /c:"www.spotify.com" /c:"accounts.spotify.com" /c:"spotifycdn.com" /c:"open-exp.spotifycdn.com" /c:"www-growth.scdn.co" /c:"o22381.ingest.sentry.io" /c:"login.app.spotify.com" /c:"encore.scdn.co" /c:"accounts.scdn.co" /c:"ap-gew1.spotify.com" /c:"www.notion.so" /c:"www.canva.com" /c:"www.intel.com" /c:"www.dell.com" /c:"developer.nvidia.com" /c:"codeium.com" /c:"inference.codeium.com" /c:"www.tiktok.com" /c:"api.github.com" /c:"datalore.jetbrains.com" /c:"plugins.jetbrains.com" /c:"elevenlabs.io" /c:"api.us.elevenlabs.io" /c:"elevenreader.io" /c:"truthsocial.com" /c:"static-assets-1.truthsocial.com" /c:"grok.com" /c:"accounts.x.ai" /c:"autodesk.com" /c:"accounts.autodesk.com" /c:"claude.ai" /c:"only-fans.uk" /c:"only-fans.me" /c:"only-fans.wtf" >nul
    if errorlevel 1 (
        echo %%a >> "%tempfile%"
    )
)
copy /y "%tempfile%" "%hostspath%" >nul
del "%tempfile%"
powershell -Command "Write-Host 'Entries removed successfully.' -ForegroundColor Green"
timeout /t 3
goto :eof

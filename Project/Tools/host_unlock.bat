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
echo ### dns.malw.link: hosts file
echo # Последнее обновление: 2 августа 2025
echo # Дополнение к zapret:
echo 157.240.245.174 instagram.com
echo 157.240.245.174 www.instagram.com
echo 157.240.245.174 b.i.instagram.com
echo 157.240.245.174 z-p42-chat-e2ee-ig.facebook.com
echo 157.240.245.174 help.instagram.com
echo 3.66.189.153 protonmail.com
echo 3.66.189.153 mail.proton.me
echo 52.223.13.41 tracker.openbittorrent.com

echo # ChatGPT, OpenAI:
echo 204.12.192.222 chatgpt.com
echo 204.12.192.222 ab.chatgpt.com
echo 204.12.192.222 auth.openai.com
echo 204.12.192.222 auth0.openai.com
echo 204.12.192.222 platform.openai.com
echo 204.12.192.222 tcr9i.chat.openai.com
echo 204.12.192.222 webrtc.chatgpt.com
echo 204.12.192.219 android.chat.openai.com
echo 204.12.192.222 api.openai.com
echo 204.12.192.221 operator.chatgpt.com
echo 204.12.192.222 sora.chatgpt.com
echo 204.12.192.222 sora.com
echo 204.12.192.222 sora.chatgpt.com
echo 204.12.192.222 videos.openai.com

echo # Сервисы Google:
echo 204.12.192.222 gemini.google.com
echo 204.12.192.222 aistudio.google.com
echo 204.12.192.222 generativelanguage.googleapis.com
echo 204.12.192.222 aitestkitchen.withgoogle.com
echo 204.12.192.219 aisandbox-pa.googleapis.com
echo 204.12.192.222 webchannel-alkalimakersuite-pa.clients6.google.com
echo 204.12.192.221 alkalimakersuite-pa.clients6.google.com
echo 204.12.192.221 assistant-s3-pa.googleapis.com
echo 204.12.192.222 proactivebackend-pa.googleapis.com
echo 204.12.192.222 o.pki.goog
echo 204.12.192.222 labs.google
echo 204.12.192.222 notebooklm.google
echo 204.12.192.222 notebooklm.google.com
echo 204.12.192.222 jules.google.com
echo 204.12.192.222 stitch.withgoogle.com

echo # Microsoft Copilot, Microsoft Rewards, Xbox, Xbox Cloud Gaming:
echo 204.12.192.222 copilot.microsoft.com
echo 204.12.192.222 sydney.bing.com
echo 204.12.192.222 edgeservices.bing.com
echo 204.12.192.221 rewards.bing.com
echo 204.12.192.222 xsts.auth.xboxlive.com
echo 204.12.192.222 xgpuwebf2p.gssv-play-prod.xboxlive.com
echo 204.12.192.222 xgpuweb.gssv-play-prod.xboxlive.com

echo # Spotify:
echo 204.12.192.222 api.spotify.com
echo 204.12.192.222 xpui.app.spotify.com
echo 204.12.192.222 appresolve.spotify.com
echo 204.12.192.222 login5.spotify.com
echo 204.12.192.222 login.app.spotify.com
echo 204.12.192.222 encore.scdn.co
echo 204.12.192.222 ap-gew1.spotify.com
echo 204.12.192.222 gew1-spclient.spotify.com
echo 204.12.192.222 spclient.wg.spotify.com
echo 204.12.192.222 api-partner.spotify.com
echo 204.12.192.222 aet.spotify.com
echo 204.12.192.222 www.spotify.com
echo 204.12.192.222 accounts.spotify.com
echo 204.12.192.221 open.spotify.com

echo # GitHub Copilot:
echo 50.7.87.84 api.github.com
echo 204.12.192.222 api.individual.githubcopilot.com
echo 204.12.192.222 proxy.individual.githubcopilot.com

echo # JetBrains:
echo 50.7.85.221 datalore.jetbrains.com
echo 107.150.34.100 plugins.jetbrains.com
echo 204.12.192.222 download.jetbrains.com

echo # ElevenLabs:
echo 204.12.192.222 elevenlabs.io
echo 204.12.192.222 api.us.elevenlabs.io
echo 204.12.192.222 elevenreader.io
echo 204.12.192.222 api.elevenlabs.io
echo 204.12.192.222 help.elevenlabs.io

echo # Truth Social
echo 204.12.192.221 truthsocial.com
echo 204.12.192.221 static-assets-1.truthsocial.com

echo # Grok
echo 204.12.192.222 grok.com
echo 204.12.192.222 accounts.x.ai
echo 204.12.192.222 assets.grok.com

echo # Tidal
echo 204.12.192.222 api.tidal.com
echo 204.12.192.222 listen.tidal.com
echo 204.12.192.222 login.tidal.com
echo 204.12.192.222 auth.tidal.com
echo 204.12.192.222 link.tidal.com
echo 204.12.192.222 dd.tidal.com
echo 204.12.192.222 resources.tidal.com
echo 204.12.192.221 images.tidal.com
echo 204.12.192.222 fsu.fa.tidal.com
echo 204.12.192.222 geolocation.onetrust.com
echo 204.12.192.222 api.squareup.com
echo 204.12.192.222 api-global.squareup.com

echo # DeepL
echo 204.12.192.222 deepl.com
echo 204.12.192.222 www.deepl.com
echo 204.12.192.222 www2.deepl.com
echo 204.12.192.222 login-wall.deepl.com
echo 204.12.192.219 w.deepl.com
echo 204.12.192.222 s.deepl.com
echo 204.12.192.222 dict.deepl.com
echo 204.12.192.222 ita-free.www.deepl.com
echo 204.12.192.222 write-free.www.deepl.com
echo 204.12.192.222 experimentation.deepl.com

echo # Deezer
echo 204.12.192.220 deezer.com
echo 204.12.192.220 www.deezer.com
echo 204.12.192.220 dzcdn.net
echo 204.12.192.220 payment.deezer.com

echo # Weather.com
echo 204.12.192.220 weather.com
echo 204.12.192.220 upsx.weather.com

echo # Guilded
echo 204.12.192.219 guilded.gg
echo 204.12.192.219 www.guilded.gg

echo # Fitbit
echo 204.12.192.219 api.fitbit.com
echo 204.12.192.219 fitbit-pa.googleapis.com
echo 204.12.192.219 fitbitvestibuleshim-pa.googleapis.com
echo 204.12.192.219 fitbit.google.com

echo # Другое:
echo 204.12.192.222 claude.ai
echo 204.12.192.220 console.anthropic.com
echo 204.12.192.222 www.notion.so
echo 50.7.85.222 www.canva.com
echo 204.12.192.222 www.intel.com
echo 204.12.192.219 www.dell.com
echo 50.7.85.219 www.tiktok.com # Только на сайте. Приложение определяет регион по оператору, а не по IP. Поэтому есть моды.
echo 142.54.189.106 web.archive.org # Блокирует от российских IP некоторые сайты
echo 204.12.192.220 developer.nvidia.com
echo 107.150.34.99 builds.parsec.app
echo 204.12.192.220 tria.ge
echo 204.12.192.220 api.imgur.com
echo 45.95.233.23 www.dyson.com
echo 45.95.233.23 www.dyson.fr
echo 45.95.233.23 usher.ttvnw.net
echo 64.188.98.242 api.manus.im
echo 185.246.223.127 4pda.to
echo 185.246.223.127 app.4pda.to
echo 185.246.223.127 s.4pda.to
echo 185.246.223.127 appbk.4pda.to

echo # Блокировка реально плохих сайтов
echo # Скримеры:
echo 0.0.0.0 only-fans.uk
echo 0.0.0.0 only-fans.me
echo 0.0.0.0 onlyfans.wtf
echo # IP Logger'ы:
echo 0.0.0.0 iplogger.org
echo 0.0.0.0 wl.gl
echo 0.0.0.0 ed.tc
echo 0.0.0.0 bc.ax
echo 0.0.0.0 maper.info
echo 0.0.0.0 2no.co
echo 0.0.0.0 yip.su
echo 0.0.0.0 iplis.ru
echo 0.0.0.0 ezstat.ru
echo 0.0.0.0 iplog.co
echo 0.0.0.0 grabify.org
echo # Мусор/реклама:
echo 0.0.0.0 log16-platform-ycru.tiktokv.com
echo 0.0.0.0 adfox.yandex.ru
echo 0.0.0.0 adfstat.yandex.ru
echo 0.0.0.0 ads-api.tiktok.com
echo 0.0.0.0 ads-api.twitter.com
echo 0.0.0.0 ads-dev.pinterest.com
echo 0.0.0.0 ads-sg.tiktok.com
echo 0.0.0.0 an.yandex.ru
echo 0.0.0.0 appmetrica.yandex.ru
echo 0.0.0.0 mc.yandex.ru
echo 0.0.0.0 amc.yandex.ru
echo ### dns.malw.link: end hosts file
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

@echo off & setlocal enableextensions
title Resetar AnyDesk

:: Verifica privilégios administrativos
reg query HKEY_USERS\S-1-5-19 >NUL || (
    echo Por favor, execute como administrador.
    pause >NUL
    exit /b
)

chcp 1252 >NUL :: Página de código para sistemas em português (ajuste conforme necessário)

:: Para o AnyDesk
call :stop_any

:: Salva configurações do usuário
if exist "%APPDATA%\AnyDesk\user.conf" copy /y "%APPDATA%\AnyDesk\user.conf" "%temp%\" >NUL
if exist "%APPDATA%\AnyDesk\thumbnails" (
    rd /s /q "%temp%\thumbnails" 2>NUL
    xcopy /c /e /h /r /y /i /k "%APPDATA%\AnyDesk\thumbnails" "%temp%\thumbnails" >NUL
)

:: Remove arquivos de configuração
del /f /q "%ALLUSERSPROFILE%\AnyDesk\*" 2>NUL
del /f /q "%APPDATA%\AnyDesk\*" 2>NUL

:: Limpa chaves do Registro
reg delete "HKEY_CURRENT_USER\Software\AnyDesk" /f >NUL 2>&1
reg delete "HKEY_LOCAL_MACHINE\Software\AnyDesk" /f >NUL 2>&1

:: Inicia o AnyDesk
call :start_any

:: Aguarda a recriação do system.conf (com timeout)
set "count=0"
:lic
if %count% geq 30 (
    echo Timeout: system.conf nao foi criado.
    pause >NUL
    exit /b
)
type "%ALLUSERSPROFILE%\AnyDesk\system.conf" | find "ad.anynet.id=" >NUL && goto restore
timeout /t 1 /nobreak >NUL
set /a count+=1
goto lic

:restore
:: Restaura configurações
call :stop_any
if exist "%temp%\user.conf" move /y "%temp%\user.conf" "%APPDATA%\AnyDesk\user.conf" >NUL
if exist "%temp%\thumbnails" (
    xcopy /c /e /h /r /y /i /k "%temp%\thumbnails" "%APPDATA%\AnyDesk\thumbnails" >NUL
    rd /s /q "%temp%\thumbnails" 2>NUL
)
call :start_any

echo *********
echo Concluido.
pause >NUL
exit /b

:start_any
:: Inicia o serviço com verificação
set "count=0"
:start_loop
if %count% geq 5 goto start_end
sc start AnyDesk >NUL
timeout /t 1 /nobreak >NUL
sc query AnyDesk | find "RUNNING" >NUL && goto start_exe
set /a count+=1
goto start_loop
:start_exe
set "AnyDesk1=%SystemDrive%\Program Files (x86)\AnyDesk\AnyDesk.exe"
set "AnyDesk2=%SystemDrive%\Program Files\AnyDesk\AnyDesk.exe"
if exist "%AnyDesk1%" start "" "%AnyDesk1%"
if exist "%AnyDesk2%" start "" "%AnyDesk2%"
:start_end
exit /b

:stop_any
:: Para o serviço com verificação
set "count=0"
:stop_loop
if %count% geq 5 goto stop_end
sc stop AnyDesk >NUL
timeout /t 1 /nobreak >NUL
sc query AnyDesk | find "STOPPED" >NUL && goto stop_exe
set /a count+=1
goto stop_loop
:stop_exe
taskkill /f /im "AnyDesk.exe" >NUL 2>&1
:stop_end
exit /b
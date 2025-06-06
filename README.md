# ResetAnydesk
Script de renovação da licença gratuita do AnyDesk
O script tenta resetar as configurações do AnyDesk para contornar a limitação de tempo, mas pode não funcionar por alguns motivos:

Restrição baseada no servidor: A limitação de tempo da versão gratuita do AnyDesk é frequentemente imposta pelo servidor do AnyDesk, não apenas por arquivos locais. Mesmo resetando configurações, o servidor pode detectar o uso contínuo ou "comercial" e reaplicar a restrição.
Arquivos residuais: O script exclui arquivos em %ALLUSERSPROFILE%\AnyDesk e %APPDATA%\AnyDesk, mas o AnyDesk pode armazenar informações adicionais no Registro do Windows (ex.: HKEY_CURRENT_USER\Software\AnyDesk) ou em outros locais não abordados.
ID persistente: Mesmo preservando o user.conf, o ID do AnyDesk pode estar vinculado à restrição no servidor, e a recriação do system.conf pode não ser suficiente para resetar a limitação.
Detecção de uso comercial: Se o AnyDesk detecta uso em redes corporativas, múltiplas conexões ou sessões longas, ele pode impor a limitação independentemente do reset local.
Sugestões de Melhorias no Script
Aqui está uma versão revisada do script com correções para evitar loops infinitos, melhorar a robustez e limpar mais completamente as configurações:

cmd

Recolher

Encapsular

Copiar
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

Mudanças realizadas:
Página de código: Alterada para 1252 (mais comum em sistemas em português).
Loops com timeout: Adicionados contadores nos loops :start_any, :stop_any e :lic para evitar loops infinitos (máximo de 5 tentativas para serviços e 30 segundos para system.conf).
Limpeza do Registro: Incluída a remoção de chaves do Registro do AnyDesk para uma limpeza mais completa.
Verificação de existência: Adicionados testes para verificar se arquivos/pastas existem antes de manipulá-los.
Saída silenciosa: Redirecionado a saída de comandos para NUL para um terminal mais limpo.
Verificação de estado do serviço: Usado sc query para confirmar se o serviço está em execução ou parado, em vez de confiar apenas no %errorlevel%.
Por que o problema pode persistir mesmo com o script revisado?
Restrições do servidor: O AnyDesk usa verificações no servidor para impor limitações de tempo na versão gratuita. Resetar arquivos locais pode não ser suficiente, especialmente se o ID do dispositivo ou a rede (IP) já estão sinalizados como "uso comercial".
Cache persistente: O AnyDesk pode armazenar informações em locais não cobertos pelo script (ex.: outros arquivos em %ProgramData% ou cache na nuvem).
Uso comercial detectado: Se o uso for interpretado como comercial (ex.: conexões frequentes, múltiplos dispositivos ou redes corporativas), a limitação será reaplicada.
Outras Soluções
Usar modo portátil:
Baixe a versão portátil do AnyDesk do site oficial e execute-a sem instalação. Isso evita configurações persistentes no sistema.
Teste se a limitação de tempo aparece no modo portátil.
Mudar a rede:
Conecte-se a uma rede diferente (ex.: hotspot do celular) para obter um novo ID do AnyDesk. Isso pode temporariamente contornar a restrição.
Entrar em contato com o suporte:
Acesse support.anydesk.com e explique o problema, fornecendo o ID do AnyDesk. Informe que você está usando a versão gratuita para fins pessoais, se aplicável.
Considerar uma licença paga:
A limitação de tempo é uma restrição da versão gratuita. Para uso contínuo, especialmente em cenários profissionais, uma licença paga (consulte preços em anydesk.com) é a solução mais confiável.
Próximos passos
Teste o script revisado: Execute o script revisado acima (salve-o como reset_anydesk.cmd e execute como administrador) e verifique se resolve.
Forneça mais detalhes: Se o problema continuar, informe:
A mensagem exata exibida pelo AnyDesk (ex.: "Sessão limitada a 30 segundos").
Se você está usando para fins pessoais ou profissionais.
Se já tentou reinstalar ou usar outra rede.
Alternativa: Considere ferramentas semelhantes, como TeamViewer (versão gratuita para uso pessoal) ou RemotePC, caso o AnyDesk continue limitando.

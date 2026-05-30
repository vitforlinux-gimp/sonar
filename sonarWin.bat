@echo off
setlocal enabledelayedexpansion

:: Verifica che il file audio esista
if not exist "ping.mp3" (
    echo ERRORE: File audio "ping.mp3" non trovato!
    echo Assicurati che il file sia nella stessa cartella dello script.
    pause
    exit /b 1
)

:: Rileva il lettore audio disponibile
set "PLAYER="

:: Controlla VLC
where vlc >nul 2>&1
if not errorlevel 1 set "PLAYER=vlc --intf dummy --play-and-exit --no-repeat"

:: Controlla MPV
if "%PLAYER%"=="" (
    where mpv >nul 2>&1
    if not errorlevel 1 set "PLAYER=mpv --no-terminal --keep-open=no --loop=no"
)

:: Controlla WMPlayer (Windows Media Player)
if "%PLAYER%"=="" (
    where wmplayer >nul 2>&1
    if not errorlevel 1 set "PLAYER=wmplayer /prefetch:1 /close"
)

:: Controlla MPlayer
if "%PLAYER%"=="" (
    where mplayer >nul 2>&1
    if not errorlevel 1 set "PLAYER=mplayer -vo null -ao win32 -really-quiet -noconsolecontrols"
)

:: Controlla FFplay
if "%PLAYER%"=="" (
    where ffplay >nul 2>&1
    if not errorlevel 1 set "PLAYER=ffplay -nodisp -autoexit -volume 100"
)

:: Se nessun lettore trovato, usa il metodo start predefinito
if "%PLAYER%"=="" (
    echo AVVISO: Nessun lettore audio avanzato trovato. Verra' usato il metodo start predefinito.
    set "PLAYER=start /min"
    set "USE_START=1"
) else (
    set "USE_START=0"
)

:: Funzione per riprodurre il suono
goto :skip_functions

:play_sound
    if "%USE_START%"=="1" (
        start /min "" "ping.mp3"
    ) else (
        %PLAYER% "ping.mp3" >nul 2>&1
    )
    goto :eof

:skip_functions

:: Suona ping.mp3 all'avvio come test
echo [TEST] Riproduzione audio di test...
call :play_sound

:: Controlla se l'IP è passato come parametro
if "%1"=="" (
    :: Se non è passato, chiedi all'utente
    set /p "TARGET_IP=Inserisci l'indirizzo IP da monitorare: "
) else (
    set "TARGET_IP=%1"
)

:: Verifica che l'IP non sia vuoto
if "%TARGET_IP%"=="" (
    echo ERRORE: Nessun IP inserito. Uscita...
    pause
    exit /b 1
)

:: Imposta tempo di default (20 secondi)
set "PING_INTERVAL=20"

:: Chiedi se vuole modificare il tempo di controllo
echo.
echo Tempo di default tra i controlli: %PING_INTERVAL% secondi
set /p "MODIFICA_TEMPO=Vuoi cambiare il tempo? (premi INVIO per usare default o inserisci un nuovo numero): "

if not "%MODIFICA_TEMPO%"=="" (
    :: Verifica che sia un numero valido (almeno 2 cifre per numeri a 1 cifra va bene)
    echo %MODIFICA_TEMPO%| findstr /r "^[1-9][0-9]*$" >nul
    if errorlevel 1 (
        echo ATTENZIONE: Valore non valido. Verra' usato il default di %PING_INTERVAL% secondi.
    ) else (
        set "PING_INTERVAL=%MODIFICA_TEMPO%"
    )
)

:: Configurazione
set "AUDIO_FILE=ping.mp3"
set "LOG_FILE=ping_log.txt"

:: Stampa intestazione
echo ========================================
echo Monitoraggio IP: %TARGET_IP%
echo Intervallo: %PING_INTERVAL% secondi
echo File audio: %AUDIO_FILE%
echo Log: %LOG_FILE%
echo ========================================
echo.
echo Premere CTRL+C per fermare il monitoraggio
echo.
echo Inizio monitoraggio...
echo.

:: Variabile per tracciare lo stato precedente
set "was_up=true"

:loop
    :: Esegui il ping e controlla il risultato
    ping -n 1 -w 2000 %TARGET_IP% >nul 2>&1

    if errorlevel 1 (
        :: IP non raggiungibile
        if not defined was_down (
            echo [!] %date% %time% - %TARGET_IP% NON RAGGIUNGIBILE

            :: Suona il file audio
            call :play_sound

            :: Scrivi nel log
            echo [!] %date% %time% - %TARGET_IP% NON RAGGIUNGIBILE >> "%LOG_FILE%"

            set "was_down=true"
        )
        set "was_up="
    ) else (
        :: IP raggiungibile
        if not defined was_up (
            echo [✓] %date% %time% - %TARGET_IP% DI NUOVO RAGGIUNGIBILE

            :: Suona anche quando torna raggiungibile
            call :play_sound

            :: Scrivi nel log
            echo [✓] %date% %time% - %TARGET_IP% DI NUOVO RAGGIUNGIBILE >> "%LOG_FILE%"

            set "was_up=true"
        )
        set "was_down="
    )

    :: Aspetta prima del prossimo controllo
    timeout /t %PING_INTERVAL% /nobreak >nul
    goto :loop
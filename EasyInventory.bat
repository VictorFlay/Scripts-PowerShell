@echo off

echo Instalando Easy Inventory...

"G:\APL\Navegadores e outros aplicativos\Easy2WSetup.exe" /verysilent /norestart

echo Aplicando configuracao...

reg import "G:\APL\Navegadores e outros aplicativos\Easy2Win.reg"

echo.
echo Processo concluido.
pause
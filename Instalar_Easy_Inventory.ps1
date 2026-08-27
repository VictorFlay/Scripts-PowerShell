#Instalar Easy Inventory
#Autor: Victor Alcantara
#Data: 29/07/2026

#Verifica se o script está sendo executado como Administrador

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Solicitando permissão de administrador..." -ForeGroundColor Yellow
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

#Caminhos dos arquivos utilizados no script

$Instalador = "G:\APL\Navegadores e outros aplicativos\Easy2WSetup.exe"
$Registro = "G:\APL\Navegadores e outros aplicativos\Easy2Win.reg"

Clear-Host

Write-Host "Iniciando instalação do Easy Inventory..." -ForegroundColor Cyan

#Verifica se os arquivos existem no caminho especificado
if (!(Test-Path $Instalador)) {
    Write-Host "O instalador do Easy Inventory não foi encontrado no caminho especificado." -ForegroundColor Red
    Write-Host "Caminho Esperado: $Instalador" -ForegroundColor Yellow

    Read-Host "Pressione Enter para sair"
    exit
}

if (-not (Test-Path $Registro)) {
    Write-Host "O arquivo de registro do Easy Inventory não foi encontrado no caminho especificado." -ForegroundColor Red
    Write-Host "Caminho Esperado: $Registro" -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit
}

try {
    Write-Host "Executando o instalador do Easy Inventory..." -ForegroundColor Cyan

    $Processo = Start-Process -FilePath $Instalador -ArgumentList "/verysilent /norestart " -Wait -PassThru

    if($Processo.ExitCode -ne 0) {
        Write-Host "Atenção: O instalador retornou o código: $($Processo.ExitCode)." -ForegroundColor Yellow
        Write-Host "Isso pode indicar que o Easy Inventory já está instalado ou que ocorreu um erro durante a instalação." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 5

    Write-Host "Aplicando configurações do Easy Inventory..." -ForegroundColor Cyan

    reg import $Registro | Out-Null

    Write-Host "Instalação concluída com sucesso." -ForegroundColor Green
    
}
catch{
    Write-Host "Ocorreu um erro durante a instalação do Easy Inventory." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Read-Host "Pressione Enter para sair..." -ForegroundColor Yellow



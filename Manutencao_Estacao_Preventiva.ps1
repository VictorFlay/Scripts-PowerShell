<#
.SYNOPSIS
    Realiza a manutenção preventiva de disco, diagnóstico de rede e serviços.

.DESCRIPTION
    Script para suporte técnico: Exibe Uptime, IP, Espaço em Disco, 
    limpa arquivos temporários e reinicia o Spooler.
    Requer privilégios de Administrador.

.NOTES
    Autor: Victor Alcantara
    Data: 08/05/2026
    Versão: 1.0
    Local: Unimed Guarulhos - Sede
#>
# 1. Trava de Segurança: Verifica se o script está sendo executado como Administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script requer privilégios de Administrador para ser executado."
    Read-Host "Pressione Enter para sair"
    break
}
# 2. Inicia a gravação do log nos seus documentos
$logFile ="$home\Documents\Manutencao_Estacao_Preventiva_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logFile -Append

Write-Host "Iniciando Manutenção Preventiva..." -ForegroundColor Green

# 3. Exibe o Uptime do sistema
$os = Get-CimInstance -Class Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "Uptime do sistema: $($uptime.Days) dias, $($uptime.Hours) horas, $($uptime.Minutes) minutos" -ForegroundColor Cyan

# 4. Exibe o espaço em disco disponível na unidade C:
try {
$volume =Get-Volume -DriveLetter C -ErrorAction Stop
$freeSpace =$volume.SizeRemaining
$freeSpaceGB =[math]::Round($freeSpace / 1GB, 2)
Write-Host "Espaço livre atual no C: : $freeSpaceGB GB" -ForeGroundColor Cyan
} catch {
Write-Warning "Não foi possível ler o espaço em disco automaticamente."
}

# 5. Diagnóstico: Reinicialização Pendente (Check de Registro)
$rebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
Write-Host "Reinicialização Pendente: $(if ($rebootPending) { "Sim" } else { "Não" })" -ForegroundColor Yellow

# 6. Diagnóstico: Resumo de Rede (IP Local)
$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_InterfaceAlias -notmatch 'Loopback' } | Select-Object -First 1 -ExpandProperty IPAddress
Write-Host "Endereço IP Local: $($ip.IPv4Address)" -ForegroundColor Cyan

# 7. Limpeza de pastas temporárias
$tempPaths = @(
"C:\Windows\Temp\*",
"$env:LOCALAPPDATA\Temp\*",
"C:\Windows\Prefetch\*"
)
Write-Host "Iniciando Limpeza de arquivos temporários..." -ForeGroundColor Yellow

foreach ($path in $tempPaths) {
# -Recurse e -Force são essenciais, mas arquivos em uso não serão apagados
Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}


# 8. Reinicia o Spooler de impressão
Write-Host "Reiniciando Spooler de Impressão..." -ForegroundColor Green
Restart-Service -Name Spooler -Force

Write-Host "`n--- PROCESSO CONCLUÍDO ---" -ForegroundColor Green

# Encerra o log e mantém a janela aberta para leitura dos resultados
Stop-Transcript
Read-Host "Pressione Enter para fechar esta janela"



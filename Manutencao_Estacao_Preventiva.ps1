<#
.SYNOPSIS
    Manutenção Preventiva de estações de trabalho Unimed - Versão 1.1

.DESCRIPTION
    Script para suporte técnico: Exibe Uptime, IP, Espaço em Disco, Inventário de hardware, testes de DNS e limpeza de lixeira 
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
    Write-Error "Este script requer privilégios de Administrador para ser executado." -ForeGroundColor Red
    Read-Host "Pressione Enter para sair"
    break
}
# 2. Inicia a gravação do log nos seus documentos
$logFile ="$home\Documents\Manutencao_Estacao_Preventiva_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logFile -Append

Write-Host "Iniciando Manutenção Preventiva..." -ForegroundColor Green

# 3. Exibe o inventário de hardware básico e identificação do usuário no domínio
$hw = Get-CimInstance -Class Win32_ComputerSystem
$bios = Get-CimInstance Win32_Bios
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
$ram = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Write-Host "Usuário: " -ForegroundColor Gray -NoNewline; Write-Host "$user" -ForegroundColor White
Write-Host "Hostname: " -ForegroundColor Gray -NoNewline; Write-Host "$($hw.Name)" -ForegroundColor White
Write-Host "Equipamento: " -ForegroundColor Gray -NoNewline; Write-Host "$($hw.Model) | S/N: $($bios.SerialNumber)" -ForegroundColor Cyan
Write-Host "CPU/RAM: " -ForegroundColor Gray -NoNewline; Write-Host "$cpu | $ram GB" -ForegroundColor Cyan

# 4. Saúde da Bateria (Apenas para laptops)
if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) {
$battery = Get-CimInstance -Class Win32_Battery
# Mapeamento simples de status
$statusDescription = switch ($battery.BatteryStatus) {
1 { "Outro" }
2 { "Em uso" }
3 { "Carga Total" }
6 { "Carregando" }
default { "Verificar" }
}
Write-Host "Status da Bateria: " -ForegroundColor Gray -NoNewline
Write-Host "$statusDescription | Carga: $($battery.EstimatedChargeRemaining)%" -ForegroundColor Yellow
}

# 5. Exibe o Uptime do sistema
$os = Get-CimInstance -Class Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "Uptime do sistema: $($uptime.Days) dias, $($uptime.Hours) horas, $($uptime.Minutes) minutos" -ForegroundColor Cyan

# 6. Exibe o espaço em disco disponível na unidade C:
try {
$volume =Get-Volume -DriveLetter C -ErrorAction Stop
$freeSpace =$volume.SizeRemaining
$freeSpaceGB =[math]::Round($freeSpace / 1GB, 2)
Write-Host "Espaço livre atual no C: : $freeSpaceGB GB" -ForeGroundColor Cyan
} catch {
Write-Warning "Não foi possível ler o espaço em disco automaticamente."
}

# 6.1 Diagnóstico de Saúde Física do Disco (S.M.A.R.T.)
try {
    $phisicalDisks = Get-PhysicalDisk | Select-Object DeviceID, FriendlyName, MediaType, HealthStatus
    Write-Host "Status de Saúde dos Discos Físicos:" -ForegroundColor Green
    foreach ($disk in $phisicalDisks) {
        $color = if ($disk.HealthStatus -eq "Healthy") { "Green" } else { "Red" }
        Write-Host " - ID: $($disk.DeviceID): " -ForeGroundColor Gray -NoNewline
        Write-Host "$($disk.FriendlyName) | $($disk.MediaType) | Status: $($disk.HealthStatus)" -ForegroundColor $color
    }
} catch {
    Write-Warning "Não foi possível obter os dados de saúde física do disco"
}

# 7. Diagnóstico: Reinicialização Pendente (Check de Registro)
$rebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
Write-Host "Reinicialização Pendente: $(if ($rebootPending) { "Sim" } else { "Não" })" -ForegroundColor Cyan

# 8. Diagnóstico: Resumo de Rede (IP Local)
$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch 'Loopback' } | Select-Object -First 1
$dnsTest = Test-NetConnection -ComputerName google.com -InformationLevel Quiet
Write-Host "Endereço IP Local: $($ip.IPAddress) | DNS OK: $(if($dnsTest){ "Sim" } else { "Não" })" -ForegroundColor Cyan

# 9. Limpeza de pastas temporárias e cache DNS
$tempPaths = @(
"C:\Windows\Temp\*",
"$env:LOCALAPPDATA\Temp\*",
"C:\Windows\Prefetch\*"
)
Write-Host "Iniciando Limpeza de arquivos temporários e esvaziando a lixeira..." -ForeGroundColor Green

foreach ($path in $tempPaths) {
# -Recurse e -Force são essenciais, mas arquivos em uso não serão apagados
Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "Limpando cache DNS (Flush DNS)..." -ForegroundColor Green
Clear-DnsClientCache -ErrorAction SilentlyContinue


# 10. Reinicia o Spooler de impressão
Write-Host "Reiniciando Spooler de Impressão..." -ForegroundColor Green
Restart-Service -Name Spooler -Force

Write-Host "`n--- PROCESSO CONCLUÍDO ---" -ForegroundColor Green

# Encerra o log e mantém a janela aberta para leitura dos resultados
Stop-Transcript
Read-Host "Pressione Enter para fechar esta janela"



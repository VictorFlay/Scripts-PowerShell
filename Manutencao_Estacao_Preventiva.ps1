<#
.SYNOPSIS
    Manutenção Preventiva de estações de trabalho Unimed - Versão 1.1

.DESCRIPTION
    Ferramenta de diagnóstico e manutenção preventiva para estações de trabalho.

    Realiza inventário básico de hardware, diagnóstico do sistema operacional,
    verificação de conectividade de rede, análise de espaço em disco, saúde dos
    discos físicos, validação de DNS corporativo, limpeza de arquivos temporários,
    reinicialização do spooler de impressão e geração automática de logs para
    suporte técnico.

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

# 5. Exibe o SO e Uptime do sistema
$os = Get-CimInstance -Class Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "Sistema Operacional: " -ForegroundColor Gray -NoNewline; Write-Host "$($os.Caption) | Build: $($os.BuildNumber)" -ForegroundColor Cyan
Write-Host "Uptime do sistema: " -ForegroundColor Gray -NoNewline; Write-Host "$($uptime.Days) dias, $($uptime.Hours) horas, $($uptime.Minutes) minutos" -ForegroundColor Cyan

# 6. Exibe o espaço em disco disponível na unidade C:
try {
$volume =Get-Volume -DriveLetter C -ErrorAction Stop
$freeSpace =$volume.SizeRemaining
$freeSpaceGB =[math]::Round($freeSpace / 1GB, 2)
Write-Host "Espaço livre atual no C:" -ForegroundColor Gray -NoNewline; Write-Host " $freeSpaceGB GB" -ForeGroundColor Cyan
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
Write-Host "Reinicialização Pendente:" -ForegroundColor Gray -NoNewline; Write-Host "$(if ($rebootPending) { "Sim" } else { "Não" })" -ForegroundColor Cyan

# 8. Diagnóstico: Resumo de Rede (IP Local)
$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch 'Loopback' } | Select-Object -First 1

$dnsGoogleTest = Test-NetConnection -ComputerName google.com -InformationLevel Quiet
Write-Host "Endereço IP:" -ForegroundColor Gray -NoNewline; Write-Host " $($ip.IPAddress) | DNS Google OK: $(if($dnsGoogleTest){ "Sim" } else { "Não" })" -ForegroundColor Cyan

$dnsInterno1 = Test-NetConnection -ComputerName 172.26.0.70 -InformationLevel Quiet
Write-Host "DNS Interno 1 OK: $(if($dnsInterno1){ "Sim" } else { "Não" })" -ForegroundColor Cyan

$dnsInterno2 = Test-NetConnection -ComputerName 172.26.0.71 -InformationLevel Quiet
Write-Host "DNS Interno 2 OK: $(if($dnsInterno2){ "Sim" } else { "Não" })" -ForegroundColor Cyan


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

# 11. Análise de gargalos de desempenho
Write-Host "`n--- TOP 5 PROCESSOS (MEMÓRIA RAM) ---" -ForeGroundColor Yellow
Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 5 -Property Name, @{Name="RAM (MB)";Expression={[math]::Round($_.WS / 1MB, 2)}} | Format-Table -AutoSize
$ramlivre = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
Write-Host "`nMemória RAM livre: $ramlivre GB" -ForegroundColor Yellow


# 12. Resumo final
Write-Host "`n--- RESUMO FINAL ---" -ForegroundColor Green

$alertasdisparados = 0

if ($uptime.Days -ge 7){Write-Host "[!] ALERTA: Recomenda-se reiniciar o sistema, pois o uptime é de $($uptime.Days) dias." -ForegroundColor Red $alertasdisparados++}
if ($freeSpaceGB -lt 20){Write-Host "[!] ALERTA: O espaço livre no C: é inferior a 20 GB." -ForegroundColor Red $alertasdisparados++}
if ((-not $dnsInterno1) -or (-not $dnsInterno2)){Write-Host "[!] ALERTA: Um ou mais DNS internos não responderam." -ForegroundColor Red $alertasdisparados++}
if ($rebootPending){Write-Host "[!] ALERTA: Há uma reinicialização pendente, reinicie o sistema o mais breve possível." -ForegroundColor Red $alertasdisparados++}

if ($alertasdisparados -eq 0){Write-Host "Nenhum alerta crítico detectado. O computador está operando dentro dos parâmetros ideais." -ForegroundColor Green}

Write-Host "`n--- PROCESSO CONCLUÍDO ---" -ForegroundColor Green

# Encerra o log e mantém a janela aberta para leitura dos resultados
Stop-Transcript
Read-Host "Pressione Enter para fechar esta janela"



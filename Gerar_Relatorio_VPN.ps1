# =====================================================================
# Relatório Home Office - VPN + Active Directory
# Autor: Victor Alcantara
# Data: 08/05/2026
# =====================================================================

Import-Module ActiveDirectory

# =====================================================
# CONFIGURACOES
# =====================================================

$PastaCSV = "C:\Auditoria_VPN\01_CSVs_Ciclo_Atual"
$PastaSaida = "C:\Auditoria_VPN\02_Relatorios"

# =====================================================
# CALCULA PERIODO AUTOMATICAMENTE
# =====================================================

$Hoje = Get-Date

if ($Hoje.Day -ge 13)
{
    $DataInicio = Get-Date -Year $Hoje.Year -Month $Hoje.Month -Day 13

    $DataFim = (Get-Date -Year $Hoje.Year -Month $Hoje.Month -Day 12).AddMonths(1)
}
else
{
    $MesAnterior = $Hoje.AddMonths(-1)

    $DataInicio = Get-Date -Year $MesAnterior.Year -Month $MesAnterior.Month -Day 13

    $DataFim = Get-Date -Year $Hoje.Year -Month $Hoje.Month -Day 12
}

Write-Host ""
Write-Host "Periodo considerado:" -ForegroundColor Yellow
Write-Host "$($DataInicio.ToShortDateString()) ate $($DataFim.ToShortDateString())"
Write-Host ""

# =====================================================
# IMPORTA TODOS OS CSVS
# =====================================================

$ArquivosCSV = Get-ChildItem -Path $PastaCSV -Filter *.csv

if (!$ArquivosCSV)
{
    Write-Host "Nenhum CSV encontrado." -ForegroundColor Red
    exit
}

$DadosVPN = foreach ($Arquivo in $ArquivosCSV)
{
    Import-Csv $Arquivo.FullName
}

# =====================================================
# AJUSTAR NOMES DAS COLUNAS
# =====================================================
#
# ALTERAR CASO O FORTIGATE UTILIZE OUTROS NOMES
#
# User
# Status
# DateTime
#
# =====================================================

$RegistrosValidos = $DadosVPN | Where-Object {

    $_.Status -eq "Connected"
}

# =====================================================
# CONVERSAO DE DATA
# =====================================================

$RegistrosTratados = foreach ($Registro in $RegistrosValidos)
{
    $DataHora = [datetime]$Registro.DateTime

    [PSCustomObject]@{

        Login = $Registro.User.Trim().ToLower()

        DataHora = $DataHora

        Data = $DataHora.Date
    }
}

# =====================================================
# FILTRA PERIODO RH
# =====================================================

$RegistrosPeriodo = $RegistrosTratados | Where-Object {

    $_.Data -ge $DataInicio.Date -and
    $_.Data -le $DataFim.Date
}

# =====================================================
# CONSULTA USUARIOS AD
# =====================================================

Write-Host "Consultando Active Directory..." -ForegroundColor Cyan

$BaseAD = Get-ADUser `
-Filter * `
-Properties DisplayName,Mail,DistinguishedName,Enabled

$IndiceAD = @{}

foreach ($Usuario in $BaseAD)
{
    $Departamento = "Nao Identificado"

    $DN = $Usuario.DistinguishedName

    $OUs = ([regex]::Matches($DN,'OU=([^,]+)') |
        ForEach-Object { $_.Groups[1].Value })

    if ($OUs.Count -gt 0)
    {
        $Departamento = $OUs[0]
    }

    $IndiceAD[$Usuario.SamAccountName.ToLower()] =
    @{
        Nome = $Usuario.DisplayName
        Departamento = $Departamento
        Email = $Usuario.Mail
        Ativo = $Usuario.Enabled
    }
}

# =====================================================
# AGRUPA DIAS DE HOME OFFICE
# =====================================================

$Resultado = $RegistrosPeriodo |
Group-Object Login |
ForEach-Object {

    $Login = $_.Name

    $DatasDistintas = $_.Group |
    Select-Object -ExpandProperty Data -Unique

    $UltimoAcesso = ($_.Group |
    Sort-Object DataHora -Descending |
    Select-Object -First 1).DataHora

    $DiasHO = $DatasDistintas.Count

    if ($IndiceAD.ContainsKey($Login))
    {
        $AD = $IndiceAD[$Login]

        $Nome = $AD.Nome
        $Departamento = $AD.Departamento
        $Email = $AD.Email
        $ContaAtiva = $AD.Ativo
    }
    else
    {
        $Nome = "USUARIO NAO LOCALIZADO"
        $Departamento = ""
        $Email = ""
        $ContaAtiva = ""
    }

    [PSCustomObject]@{

        Login = $Login

        NomeCompleto = $Nome

        Departamento = $Departamento

        DiasHomeOffice = $DiasHO

        QuantidadeConexoes = $_.Count

        UltimoAcesso = $UltimoAcesso

        Email = $Email

        ContaAtiva = $ContaAtiva
    }
}

# =====================================================
# ORDENA
# =====================================================

$ResultadoFinal =
$Resultado |
Sort-Object NomeCompleto

# =====================================================
# ARQUIVO FINAL
# =====================================================

$NomeArquivo = "Relatorio_HomeOffice_{0}.xlsx" -f (Get-Date -Format "yyyy-MM")

$ArquivoSaida = Join-Path $PastaSaida $NomeArquivo

# =====================================================
# EXPORTA EXCEL
# =====================================================

$ResultadoFinal |
Export-Excel `
-Path $ArquivoSaida `
-WorksheetName "HomeOffice" `
-AutoSize `
-BoldTopRow `
-FreezeTopRow `
-TableName RelatorioHO

Write-Host ""
Write-Host "Relatorio gerado com sucesso:" -ForegroundColor Green
Write-Host $ArquivoSaida -ForegroundColor Green
Write-Host ""
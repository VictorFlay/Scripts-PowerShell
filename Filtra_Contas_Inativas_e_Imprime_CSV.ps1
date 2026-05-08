<#
.SYNOPSIS
    Levantamento de contas desabilitadas e inativas no AD da Unimed.
.DESCRIPTION
    Gera um CSV com usuários desabilitados há mais de 180 dias e salva no diretório documentos.
.NOTES
    Autor: Victor Alcantara
    Data: 23/04/2026
#>

#Define a data de corte (6 meses atrás)
$dataCorte = (Get-Date).AddDays(-180)

#Busca as contas desabilitadas e inativas e exporta para o arquivo CSV
Get-ADUser -Filter 'Enabled -eq $false' -Properties LastLogonDate |
Where-Object { $_.LastLogonDate -lt $dataCorte } |
Select-Object Name, SamAccountName, LastLogonDate |
Sort-Object LastLogonDate |
Export-Csv -Path "$home\Documents\Contas_Inativas_AD_Unimed.csv" -NoTypeInformation -Delimiter ";"


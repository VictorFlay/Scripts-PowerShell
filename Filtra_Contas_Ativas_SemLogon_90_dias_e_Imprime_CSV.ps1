<#
.SYNOPSIS
	Higienização de contas ativas sem login recente no AD da Unimed Guarulhos
.DESCRIPTION
	Gera um CSV com usuários que estão ativos (Enabled, mas que não possuem registro de login nos últimos 90 dias)
.NOTES
	Autor: Victor Alcantara
	Data: 06/05/2026
#>
#Define a data de corte (90 dias atrás)
$dataCorte = (Get-Date).AddDays(-90)

# Busca as contas ativas que não logaram no período e exporta um CSV
Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonDate |
Where-Object {

#Filtra quem tem data de login anterior ao corte OU nunca logou ($null)
($_.LastLogonDate -lt $dataCorte) -and ($_.LastLogonDate -ne $null)
} |

Select-Object Name, SamAccountName, LastLogonDate |
Sort-Object LastLogonDate |

Export-Csv -Path "$home\Documents\Contas_Ativas_SemLogon_90_dias.csv" -NoTypeInformation -Delimiter ";" -Encoding UTF8
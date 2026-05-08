<#
.SYNOPSIS
    Filtro de contas com o atributo 'Senha nunca expira' no AD
.DESCRIPTION
    Gera um CSV com usuários com atributo 'Senha Nunca expira' e Salva nos Documentos.
.NOTES
    Autor: Victor Alcantara
    Data: 23/04/2026
#>

#Filtra usuários com o atributo 'Senha Nunca Expira' e exporta para um arquivo CSV
Get-ADUser -Filter 'PasswordNeverExpires -eq $true -and Enabled -eq $true' -Properties PasswordNeverExpires |
Select-Object Name, SamAccountName |
Export-Csv -Path "$home\Documents\Senha_Nunca_Expira_AD_Unimed.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"
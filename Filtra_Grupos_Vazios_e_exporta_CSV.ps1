<#
.SYNOPSIS
    Levantamento de grupos sem membros (vazios)
.DESCRIPTION
    Filtra grupos sem membros e exporta para um arquivo CSV no diretório documentos
.NOTES
    Autor: Victor Alcantara
    Data: 23/04/2026
#>

Get-ADGroup -Filter * |
Where-Object {-not (Get-ADGroupMember -Identity $_.DistinguishedName)} |
Select-Object Name, GroupCategory, GroupScope |
Export-Csv -Path "$home\Documents\Grupos_Vazios.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"
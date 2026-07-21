ping.exe -t 192.168.0.108 | ForEach-Object {
    if ($_ -ne "") {
        "{0} - {1}" -f (Get-Date -Format "dd/MM/yyyy HH:mm:ss"), $_ | Tee-Object -FilePath "C:\Users\victor.alcantara\Documents\Victor Alcantara\ping_impressora_atd_presencial.txt" -Append
    }
}
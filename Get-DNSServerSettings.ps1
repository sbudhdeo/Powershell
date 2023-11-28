<#  .Description
		
		Title: Get DNS Server Settings
		Created: 2023-07-21
		Author: Samir Budhdeo
		Version 1.0
		
		This script will get the DNS server settings for Windows Servers specified under a specific OU

#>

$title = "DNSServerSettings"
$Date = Get-Date -format yyyyMMdd
$scriptRoot = "C:\Scripts\DNSServerSettings\"
$resultPath = $scriptRoot
$csvFile = $scriptRoot + $title + $Date + ".csv"
if (Test-Path $csvFile) {Remove-Item $csvFile -force}

$AllServers = Get-ADComputer -SearchBase "OU=Servers,OU=Infrastructure,OU=Company,DC=domain,DC=com" -Filter {OperatingSystem -Like "Windows Server*"}
$CSVOutput = @()

ForEach ($Server in $AllServers) {
    try {
        if (Test-Connection -ComputerName $Server.Name -Count 1 -Quiet) {
            $Result = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" -Property * -ComputerName $Server.Name
            $output = New-Object PSObject 
            $output | Add-Member NoteProperty "ComputerName" $Server.Name
            $IPv4Address = ($Result | Where-Object {$_.IPEnabled -eq $True -and $_.IPAddress -ne $null}).IPAddress[0]
            $output | Add-Member NoteProperty "IPAddress" $IPv4Address
            $DNSServerSearchOrder = ($Result.DNSServerSearchOrder -join ", ")  # Convert the array to a comma-separated string
            $output | Add-Member NoteProperty "DNSServerSearchOrder" $DNSServerSearchOrder
            $CSVOutput += $output
        } else {
            # Write-Host "Server $($Server.Name) is not responding to ping. Adding to CSV with status."
            $output = New-Object PSObject 
            $output | Add-Member NoteProperty "ComputerName" $Server.Name
            $output | Add-Member NoteProperty "IPAddress" "N/A"
            $output | Add-Member NoteProperty "DNSServerSearchOrder" "N/A"
            $output | Add-Member NoteProperty "Status" "Not responding to ping"
            $CSVOutput += $output
        }
    } catch {
        Write-Host "Error occurred while processing $($Server.Name): $_"
        $output = New-Object PSObject 
        $output | Add-Member NoteProperty "ComputerName" $Server.Name
        $output | Add-Member NoteProperty "IPAddress" "N/A"
        $output | Add-Member NoteProperty "DNSServerSearchOrder" "N/A"
        $output | Add-Member NoteProperty "Status" "Error: $($_.Exception.Message)"
        $CSVOutput += $output
    }
}

$CSVOutput | Export-Csv -Path $csvFile -NoTypeInformation

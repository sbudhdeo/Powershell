<#  .Description

		Created: 2018-08-01
		Author: Samir Budhdeo
		Version 1.0
		
		The following script will parse a zone in Active Directory that is older than a specified time and perform a ping check on A records.
    Useful for identifying objects that may no longer exist.
#>

$names = (Get-DnsServerResourceRecord -ComputerName dnsServer -ZoneName "domain.com" -RRType "A" | Where {($_.Timestamp -le (get-date).adddays(-1095)) -AND ($_.Timestamp -like "*/*")}).HostName

foreach ($name in $names) {

  if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue) {
    $ipAddress = [System.Net.Dns]::GetHostAddresses($name)
    Write-Host "$name,UP,$ipAddress"
  }
  else {
    Write-Host "$name,DOWN"
  }
}

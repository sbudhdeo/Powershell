<#  .Description
		
		Title: Format disks in Windows
		Created: 2023-08-06
		Author: Samir Budhdeo
		Version 1.0
		
		Main idea was taken from https://stackoverflow.com/questions/54792301/powershell-drive-configuration-using-loops-and-arrays
		The objective of this script is in my case to provision a SQL server with 4 disks.  Other additions and checks have been added 
		to this.

#>


$DiskPrepInfo = @'
DiskNumber, DriveLetter, Label
1, D, DATA
2, L, LOGS
3, T, TEMP
4, Y, BACKUP TEMP
'@ | ConvertFrom-Csv

foreach ($DPI_Item in $DiskPrepInfo) {
    $diskNumber = $DPI_Item.DiskNumber
    $driveLetter = $DPI_Item.DriveLetter
    $label = $DPI_Item.Label

    $disk = Get-Disk -Number $diskNumber
    if ($disk.OperationalStatus -ne "Online") {
        # Disk is not online, proceed with initialization
        Set-Disk -Number $diskNumber -IsOffline $False
        Start-Sleep -Seconds 5
        Set-Disk -Number $diskNumber -IsReadOnly $False
        Start-Sleep -Seconds 5
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
        Start-Sleep -Seconds 5
    }
    else {
        Write-Host "Disk $diskNumber is already online. Skipping initialization..."
    }

    $partition = Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter -eq $driveLetter }
    if ($partition) {
        Write-Host "Disk $diskNumber is already initialized and formatted. Skipping..."
    }
    else {
        New-Partition -DiskNumber $diskNumber -DriveLetter $driveLetter -UseMaximumSize
        Start-Sleep -Seconds 10
        $FV_Params = @{
            DriveLetter        = $driveLetter
            FileSystem         = 'NTFS'
            NewFileSystemLabel = $label
            AllocationUnitSize = 65536
            Force              = $True
            Confirm            = $False
        }
        Format-Volume @FV_Params
    }
}
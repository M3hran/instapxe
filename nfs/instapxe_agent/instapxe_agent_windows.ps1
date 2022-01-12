#instapxe_agent_windows.ps1
 
## Timestamp function for logging.
function Get-TimeStamp {  
    return "{0:MM/dd/yyyy}-{0:HH:mm:ss}" -f (Get-Date)  
}

function Get-ClusterLocation {

        (Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$False) | out-null
        (Install-Module -Name PSDiscoveryProtocol -Force -Confirm:$False) | out-null
        $Packet = Invoke-DiscoveryProtocolCapture -Force
        $data = Get-DiscoveryProtocolData -Packet $Packet
        $rack = $data.Device.Substring(1,1)
        $u = $data.Port.Split("/")[1]
        $location = "Rack$($rack)-U$($u)"
        return $location
}


$API = "http://172.17.1.3:9010/api/device/"

## Install NFS-Client.
#Install-WindowsFeature -Name NFS-Client

#Write-Output "$(Get-TimeStamp) Installed NFS-Client." | Out-File -encoding utf8 -FilePath $logFile -Append

## Configure NFS user mapping registry values.
#New-ItemProperty -Path "HKLM:\Software\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousGid" -Value 0 -PropertyType DWord
#New-ItemProperty -Path "HKLM:\Software\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousUid" -Value 0 -PropertyType DWord

#Write-Output "$(Get-TimeStamp) Created registry keys for NFS root user mapping." | Out-File -encoding utf8 -FilePath $logFile -Append
 
## Restart NFS-Client.
#nfsadmin client stop
#nfsadmin client start

#Write-Output "$(Get-TimeStamp) Restarted NFS Cleint." | Out-File -encoding utf8 -FilePath $logFile -Append

mount.exe -o anon 172.17.1.3:/reports Z:

#collect system info
$sysinfo = Get-ComputerInfo

## Create a log file.
$SVCTAG = $sysinfo.BiosSeralNumber
$MANUFACTURER = $sysinfo.BiosManufacturer
if ([string]::IsNullOrWhiteSpace($MANUFACTURER))
{
   $MANUFACTURER = "Dell Inc."
}

$MODEL = $sysinfo.CsModel
if ([string]::IsNullOrWhiteSpace($MODEL))
{
   $MODEL = "PowerEdge R620"
}

$OS_NAME= $sysinfo.OsName
$SVCTAG=$SVCTAG.Trim()
$MAC = $(Get-WmiObject win32_networkadapterconfiguration | where {$_.IPAddress -ne $null} | select macaddress).macaddress

$LOGPATH = "Z:\build\" + "$SVCTAG\"
$LOGFILE = "$LOGPATH" + "$SVCTAG" + "_imaging_log.txt"
$JSONPATH= "$LOGPATH" + "json\"
$JSONFILE= "$JSONPATH" + "$SVCTAG" + "_osimaging.json"
$SUMFILE = "$LOGPATH" + "$SVCTAG" + "_build_summary.csv"
$SUMJSON = "$LOGPATH" + "$SVCTAG" + "_build_summary.json"

#if logpath && logfile don't exist create them
If(!(test-path $LOGPATH))
{
      
      try {
       
        New-Item -ItemType Directory -Force -Path $LOGPATH -ErrorAction Stop | Out-Null
       }
      catch {
        throw $_.Exception.Message
      }

}
If(!(test-path $LOGFILE))
{
      try {

        New-Item -ItemType File -Force -Path $LOGFILE -ErrorAction Stop
        Write-Output "$(Get-TimeStamp) Logfile created..." | Out-File -encoding utf8 -FilePath $LOGFILE -Append | Out-Null
      }
      catch {
        throw $_.Exception.Message
      }

}

#if json path and file don't exist create them
If(!(test-path $JSONPATH))
{
      
      try {

        New-Item -ItemType Directory -Force -Path $JSONPATH -ErrorAction Stop | Out-Null
       }
      catch {
        throw $_.Exception.Message
      }

}
If(!(test-path $JSONFILE))
{
      try {

        New-Item -ItemType File -Force -Path $JSONFILE -ErrorAction Stop | Out-Null
        Write-Output "$(Get-TimeStamp) json file created..." | Out-File -encoding utf8 -FilePath $LOGFILE -Append
      }
      catch {
        throw $_.Exception.Message
      }

}

$LEGALTXT = @"

 __                 __                              
|__| ____   _______/  |______  _________  ___ ____  
|  |/    \ /  ___/\   __\__  \ \____ \  \/  // __ \ 
|  |   |  \\___ \  |  |  / __ \|  |_> >    <\  ___/ 
|__|___|  /____  > |__| (____  /   __/__/\_ \\___  >
        \/     \/            \/|__|        \/    \/ 


Copyright 2021 @ Parallax System LLC. All Rights Reserved.
https://instapxe.com/eula

"@

Write-Output $LEGALTXT | Out-File -encoding utf8 -FilePath $LOGFILE -Append

$TXT1 = @"

Manufacturer:       $MANUFACTURER
Model:              $MODEL
SVC TAG:            $SVCTAG
OS Image:           $OS_NAME

"@

Write-Output $TXT1 | Out-File -encoding utf8 -FilePath $LOGFILE -Append


New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters -Name AllowInsecureGuestAuth -Value 1

$Inventory = New-Object System.Collections.ArrayList
$ComputerInfo = New-Object System.Object

$ComputerHW = Get-WmiObject -Class Win32_ComputerSystem | select Manufacturer,Model,NumberOfProcessors,@{Expression={[math]::round($_.TotalPhysicalMemory / 1GB)};Label="TotalPhysicalMemoryGB"}

$ComputerCPU = Get-WmiObject win32_processor | select DeviceID,Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors
  
$ComputerDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | select DeviceID,VolumeName,@{Expression={$_.Size / 1GB};Label="SizeGB"}


$ComputerInfoManufacturer = $MANUFACTURER
$ComputerInfoModel = $MODEL
$ComputerInfoNumberOfProcessors = $ComputerHW.NumberOfProcessors
$ComputerInfoProcessorID = $ComputerCPU.DeviceID
$ComputerInfoProcessorManufacturer = $ComputerCPU.Manufacturer
$ComputerInfoProcessorName = $ComputerCPU.Name
$ComputerInfoNumberOfCores = $ComputerCPU.NumberOfCores
$ComputerInfoNumberOfLogicalProcessors = $ComputerCPU.NumberOfLogicalProcessors
$ComputerInfoRAM = $ComputerHW.TotalPhysicalMemoryGB
$ComputerInfoDiskDrive = $ComputerDisks.DeviceID
$ComputerInfoDriveName = $ComputerDisks.VolumeName
$ComputerInfoSize = $ComputerDisks.SizeGB
$ComputerBuildTimeStamp = $sysinfo.WindowsInstallDateFromRegistry
$ComputerBiosCaption = $sysinfo.BiosCaption
$ComputerBiosFirmwareType = $sysinfo.BiosFirmwareType
$ComputerCsNumberOfProcessors = $sysinfo.CsNumberOfProcessors

$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Time" -Value "$ComputerBuildTimeStamp" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "SVCTAG" -Value "$SVCTAG" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "$MANUFACTURER" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Model" -Value "$MODEL" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "BiosVersion" -Value "$ComputerBiosCaption" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "BiosType" -Value "$ComputerBiosFirmwareType" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfProcessors" -Value "$ComputerCsNumberOfProcessors" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorID" -Value "$ComputerInfoProcessorID" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorManufacturer" -Value "$ComputerInfoProcessorManufacturer" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorName" -Value "$ComputerInfoProcessorName" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfCores" -Value "$ComputerInfoNumberOfCores" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfLogicalProcessors" -Value "$ComputerInfoNumberOfLogicalProcessors" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "RAM" -Value "$ComputerInfoRAM" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskDrive" -Value "$ComputerInfoDiskDrive" -Force
#$ComputerInfo | Add-Member -MemberType NoteProperty -Name "DriveName" -Value "$ComputerInfoDriveName" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Size" -Value "$ComputerInfoSize"-Force

$Inventory.Add($ComputerInfo) | Out-Null

$ComputerHW = ""
$ComputerCPU = ""
$ComputerDisks = ""

$Inventory | Export-Csv $SUMFILE
$Inventory | ConvertTo-Json | Out-File -encoding utf8 -FilePath $SUMJSON
Write-Output "$(Get-TimeStamp) System build summary created..." | Out-File -encoding utf8 -FilePath $LOGFILE -Append




$jsonpayload="{`"manufacturer`":`"$MANUFACTURER`",`"svctag`":`"$SVCTAG`",`"model`":`"$MODEL`",`"mac`":`"$MAC`",`"location`":`"$(Get-ClusterLocation)`",`"time`":`"$(Get-TimeStamp)`", `"level`":`"info`",`"stage`":`"imaging`",`"os_name`":`"$OS_NAME`",`"msg`":`"completed`"}"

Write-Output $jsonpayload | Out-File -encoding utf8 -FilePath $JSONFILE -Append






Write-Output "$(Get-TimeStamp) OS Image Deployment Completed. Shutting Down..." | Out-File -encoding utf8 -FilePath $LOGFILE -Append


$Param = @{
	
	Method 	= "POST"
	Uri	= $API
        ContentType	= "application/json"
	Body	= $jsonpayload

}
Invoke-RestMethod @Param





shutdown.exe /s

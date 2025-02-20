# ------------------------------------------------------------------------- #
# Variables
# ------------------------------------------------------------------------- #

# Change $ZabbixInstallPath to wherever your Zabbix Agent is installed

$ZabbixInstallPath = "$Env:Programfiles\Zabbix Agent 2"
$ZabbixConfFile = "$Env:Programfiles\Zabbix Agent 2"

# Do not change the following variables unless you know what you are doing

$Sender = "$ZabbixInstallPath\zabbix_sender.exe"
$Senderarg1 = '-vv'
$Senderarg2 = '-c'
$Senderarg3 = "$ZabbixConfFile\zabbix_agent2.conf"
$Senderarg4 = '-i'
$Senderarg5 = '-k'
$SenderargInvStatus = '\wininvstatus.txt'


# ------------------------------------------------------------------------- #
# This part gets the inventory data and writes it to a temp file
# ------------------------------------------------------------------------- #

$Winarch = Get-CimInstance Win32_OperatingSystem | Select-Object OSArchitecture | foreach { $_.OSArchitecture }
$WinOS = Get-CimInstance Win32_OperatingSystem | Select-Object Caption | foreach { $_.Caption }
$WinBuild = Get-CimInstance Win32_OperatingSystem | Select-Object BuildNumber | foreach { $_.BuildNumber }
$ModelNum = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Model | foreach { $_.Model }
$Manuf = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer | foreach { $_.Manufacturer }
$SerialNum = gwmi win32_bios | Select-Object SerialNumber | foreach { $_.SerialNumber }
$WinDomain = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Domain | foreach { $_.Domain }
$Owner = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object PrimaryOwnerName | foreach { $_.PrimaryOwnerName }
$Loggedon = Get-CimInstance -ClassName Win32_ComputerSystem  | Select-Object UserName | foreach { $_.UserName }
$IPAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).IPAddress | select-object -first 1
$IPGateway = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).DefaultIPGateway | select-object -first 1
$PrimDNSServer = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).DNSServerSearchOrder | select-object -first 1
$BIOS = Get-WmiObject -Class Win32_BIOS
$BIOSageInYears = (New-TimeSpan -Start ($BIOS.ConvertToDateTime($BIOS.releasedate).ToShortDateString()) -End $(Get-Date)).Days / 365
$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
$OSInstallDate = ($OperatingSystem.ConvertToDateTime($OperatingSystem.InstallDate).ToShortDateString())
$BIOSDate = $BIOS.ConvertToDateTime($BIOS.releasedate).ToShortDateString()
$NumberOfProcessors = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfProcessors
$NumberOfCores = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
$NumberOfLogicalProcessors = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum 

$HardwareFullDetails = "Processors: $NumberOfProcessors; Cores: $NumberOfCores; Logical Processors: $NumberOfLogicalProcessors"
$outputHardwareFullDetails = "- inv.HardwareFullDetails " + '"' + "$HardwareFullDetails" + '"'

$outputWinOS = "- inv.WinOS "
$outputWinOS += '"'
$outputWinOS += "$($WinOS)"
$outputWinOS += '"'

$outputModelNum = "- inv.ModelNum "
$outputModelNum += '"'
$outputModelNum += "$($ModelNum)"
$outputModelNum += '"'

$outputManuf = "- inv.Manuf "
$outputManuf += '"'
$outputManuf += "$($Manuf)"
$outputManuf += '"'

$outputWinDomain = "- inv.WinDomain "
$outputWinDomain += '"'
$outputWinDomain += "$($WinDomain)"
$outputWinDomain += '"'

$outputOwner = "- inv.Owner "
$outputOwner += '"'
$outputOwner += "$($Owner)"
$outputOwner += '"'

$outputLoggedon = "- inv.Loggedon "
$outputLoggedon += '"'
$outputLoggedon += "$($Loggedon)"
$outputLoggedon += '"'

$outputOSInstallDate = "- inv.OSInstallDate "
$outputOSInstallDate += '"'
$outputOSInstallDate += "$($OSInstallDate)"
$outputOSInstallDate += '"'

$outputBIOSDate = "- inv.BIOSDate "
$outputBIOSDate += '"'
$outputBIOSDate += "$($BIOSDate)"
$outputBIOSDate += '"'

$outputNumberOfProcessors = "- inv.NumberOfProcessors "
$outputNumberOfProcessors += '"'
$outputNumberOfProcessors += "$NumberOfProcessors"
$outputNumberOfProcessors += '"'

$outputNumberOfCores = "- inv.NumberOfCores "
$outputNumberOfCores += '"'
$outputNumberOfCores += "$NumberOfCores"
$outputNumberOfCores += '"'

$outputNumberOfLogicalProcessors = "- inv.NumberOfLogicalProcessors "
$outputNumberOfLogicalProcessors += '"'
$outputNumberOfLogicalProcessors += "$NumberOfLogicalProcessors"
$outputNumberOfLogicalProcessors += '"'

Write-Output "- inv.WinArch $Winarch" | Out-File -Encoding "ASCII" -FilePath $env:temp$SenderargInvStatus
Add-Content $env:temp$SenderargInvStatus $outputWinOS
Add-Content $env:temp$SenderargInvStatus "- inv.WinBuild $WinBuild"
Add-Content $env:temp$SenderargInvStatus $outputModelNum
Add-Content $env:temp$SenderargInvStatus $outputManuf
Add-Content $env:temp$SenderargInvStatus "- inv.SerialNum $SerialNum"
Add-Content $env:temp$SenderargInvStatus $outputWinDomain
Add-Content $env:temp$SenderargInvStatus $outputOwner
Add-Content $env:temp$SenderargInvStatus $outputLoggedon
Add-Content $env:temp$SenderargInvStatus "- inv.IPAddress $IPAddress"
Add-Content $env:temp$SenderargInvStatus "- inv.IPGateway $IPGateway"
Add-Content $env:temp$SenderargInvStatus "- inv.PrimDNSServer $PrimDNSServer"
Add-Content $env:temp$SenderargInvStatus $outputBIOSDate
Add-Content $env:temp$SenderargInvStatus $outputOSInstallDate

Add-Content $env:temp$SenderargInvStatus $outputHardwareFullDetails
# ------------------------------------------------------------------------- #
# This part sends the information in the temp file to Zabbix
# ------------------------------------------------------------------------- #

& $Sender $Senderarg1 $Senderarg2 $Senderarg3 $Senderarg4 $env:temp$SenderargInvStatus -s "$env:computername"

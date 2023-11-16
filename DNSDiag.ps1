<#
	.SYNOPSIS
	Collect DNSDiag Logs 

	.DESCRIPTION
	Runs locally on DC hosting DNS to check if DNS Server is in use

	.NOTES
    Author: Michael Maher

#>
[cmdletbinding()]
Param()
<#

Get-DnsServerDiagnostics


    SaveLogsToPersistentStorage          : False
    Queries                              : True
    Answers                              : False
    Notifications                        : False
    Update                               : False
    QuestionTransactions                 : True
    UnmatchedResponse                    : False
    SendPackets                          : False
    ReceivePackets                       : True
    TcpPackets                           : True
    UdpPackets                           : True
    FullPackets                          : False
    FilterIPAddressList                  : 
    EventLogLevel                        : 4
    UseSystemEventLog                    : False
    EnableLoggingToFile                  : True
    EnableLogFileRollover                : False
    LogFilePath                          : c:\temp\debug3.log
    MaxMBFileSize                        : 500000000
    WriteThrough                         : False
    EnableLoggingForLocalLookupEvent     : False
    EnableLoggingForPluginDllEvent       : False
    EnableLoggingForRecursiveLookupEvent : False
    EnableLoggingForRemoteServerEvent    : False
    EnableLoggingForServerStartStopEvent : False
    EnableLoggingForTombstoneEvent       : False
    EnableLoggingForZoneDataWriteEvent   : False
    EnableLoggingForZoneLoadingEvent     : False

#>

#region Variables

$kScript = 'DNSDiags'
$Kdate = (Get-Date).ToString('yyyy-MM-dd_H-mm')
$klogRoot = 'c:\Scripts\Logs'

$splatDNSDiagOn = @{

    TcpPackets           = $True 
    UdpPackets           = $True
    ReceivePackets       = $True
    Queries              = $True
    QuestionTransactions = $True
    EnableLoggingToFile  = $True
    LogFilePath          = "$klogRoot\$kScript$Kdate.txt"
    MaxMBFileSize        = 500000000 # 500MB
    Verbose              = $True
}

$splatDNSDiagOff = @{

    EnableLoggingForLocalLookupEvent = $False 
    EnableLoggingForPluginDllEvent = $False 
    EnableLoggingForRecursiveLookupEvent = $False 
    EnableLoggingForRemoteServerEvent = $False 
    EnableLoggingForServerStartStopEvent =  $False 
    EnableLoggingForTombstoneEvent = $False 
    EnableLoggingForZoneDataWriteEvent =  $False 
    EnableLoggingForZoneLoadingEvent=  $False
    LogfilePath          = $null
    Verbose              = $True
}

#endregion

# Reset Diags
# Get-DnsServerDiagnostics -ComputerName "SLO-DCU-01" | 
#    Select -TcpPackets, -UdpPackets | 
#    Set-DnsServerDiagnostics -ComputerName $ENV:COMPUTERNAME

#region Logging
    if(!(Test-Path -Path "$klogRoot\$Kscript" )){
        New-Item -ItemType directory -Path "$klogRoot\$Kscript"
    }
    Start-Transcript -Path "$klogRoot\$Kscript\$Kdate-$kScript.log"
#endregion


If (-not(Get-DnsServerDiagnostics).LogFilePath){

    Write-Verbose "DNS has not been logging so we will turn it on and collect on the next run"
    Set-DnsServerDiagnostics @splatDNSDiagOn
    break

}

#Write-Verbose "Suspending debug logging"

#Set-DnsServerDiagnostics @splatDNSDiagOff


$time = (Get-Date(Get-Date).ToUniversalTime() -Format "yyyy-MM-dd HH:mm:ss")

Write-Verbose "Parsing DNS log ..."
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
$parsed = $null
$parsed = (Get-Content "$klogRoot\$kScript*.txt" | 
    Select-String -CaseSensitive "PACKET" | 
    Select-Object Line | 
    Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" -AllMatches).Matches.Value |
    Group-Object | 
    Select-Object -Property Count, @{n="IP";e={$_.Name}}, @{n="Client";e={([System.Net.Dns]::GetHostbyAddress($_.Name)).hostname}} | 
    Sort-Object -Descending -Property Count |
    Where-Object {$_.Client -notlike "*-DCU-*"} |
    Where-Object {$_.Client -notlike "*-DCR-*"} 

$stopwatch.Stop()

Write-Verbose "Parsing took $([math]::Round($stopwatch.Elapsed.TotalSeconds,2)) seconds"
  
    
$parsed | Add-Member -MemberType NoteProperty -Name 'Time' -Value $time -Verbose 
$parsed | Add-Member -MemberType NoteProperty -Name 'DNSServer' -Value $env:COMPUTERNAME -Verbose
$parsed
$parsed | Export-Csv -Path "$klogRoot\$kScript$Kdate.csv" -Verbose -NoTypeInformation 


Write-Verbose "Cleaning up processed files"
Write-Verbose "Stopping DNS logging momentarily"
Set-DnsServerDiagnostics @splatDNSDiagOff 
Start-Sleep -Seconds 360 -Verbose
Remove-Item -Path "$klogRoot\$kScript*.txt" -Verbose
Set-DnsServerDiagnostics @splatDNSDiagOn 

Stop-Transcript

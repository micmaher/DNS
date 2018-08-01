### Snippets for working with DNS Caching

################## Get all Domain Controllers 
$dc = Get-ADDomainController -Filter * | Select name
$dc.Count



# Get Cache Settings
$results = foreach ($d in $dc){  
    $cacheSettings = Get-DnsServerCache -ComputerName $d.name |
    Select @{Name='Server'; Expression={$d.name}}, MaxTTL, ZoneName
    }

 ################# Examine Cache Contents
$results = foreach ($d in $dc){
    $cache = Show-DnsServerCache
    $cache | Where-Object {$_.TimeToLive -gt "23:00:00"} | Sort-Object -Property TimeToLive -Descending
    $cache | where {$_.hostname -like "*kleinwortbensons*"}
    $cache | Where-Object {$_.RecordData.IPv4Address -like "193.*"}
    }

break

####################### Drop Cache Entirely EMEA Only ################

 
Start-Transcript -Path $env:TEMP\DNSCacheChange2.log
$emea = @(
'DC-01','DC-02','DC-03','DC-04')
 
Foreach ($dc in $emea){
Set-DnsServerCache -MaxTtl 0 -ComputerName $dc
}


Foreach ($dc in $emea){
Get-DnsServerCache -ComputerName $dc
}


Clear-DnsServerCache -ComputerName $dc -force
Resolve-DnsName www.google.com  -Server $dc
Show-DnsServerCache -ComputerName $dc | select -First 100
Get-DnsServerCache -ComputerName $dc


################## Drop Cache Time

Start-Transcript -Path $env:TEMP\DNSCacheChange.log

$timespan = New-TimeSpan -Minutes 15


# Record pre-change values
$dc = Get-ADDomainController -Filter * | where {$_.name -notlike "NDH*"} 
$dc = $dc | where {$_.name -notlike "CHD*"}

foreach ($d in $dc){
    Get-DnsServerCache -ComputerName $d.name -WarningAction SilentlyContinue | 
        Select @{Name='Server'; Expression={$d.name}}, @{Name='MaxTTL'; Expression={($_.maxTTL)}}
}



# Make the change
foreach ($d in $dc){
    Set-DnsServerCache -MaxTtl $timespan -ComputerName $d.name 
}


# Validate change
foreach ($d in $dc){
    Get-DnsServerCache -ComputerName $d.name -WarningAction SilentlyContinue | 
        Select @{Name='Server'; Expression={$d.name}}, @{Name='MaxTTL'; Expression={($_.maxTTL)}}
}

 
 
# Clear the cache
foreach ($d in $dc){
    Clear-DnsServerCache -ComputerName $d.name 
}



# Let the cache repopulate for a bit and example the TTL values
foreach ($d in $dc){
    $cacheSample = Show-DnsServerCache -ComputerName $d.name  | select -First 20
    $cacheSample | Sort-Object TimeToLive -Descending 
}

Stop-Transcript

Function Get-ReverseInfo{ 
<#

    .SYNOPSIS
       Perform a bulk reverse lookup

           Get-ReverseInfo -Subnet '10.33.19.0' -DNSServer 'ns1.contoso.com'

<#

    .SYNOPSIS
       Perform a bulk reverse lookup
    .DESCRIPTION
       This function performs a reverse lookup on an entire class C subnet

    .EXAMPLE
		Get-ReverseInfo -Subnet '10.33.19.0' -DNSServer 'dnsmaster01.drt01.corp.tripadvisor.com'
	
	.NOTES
		
#>     
    [cmdletbinding()]
    Param(
          [Parameter(ValueFromPipeline=$true,
                     ValueFromPipelineByPropertyName=$true,
                     Position=0)]
          [ValidateScript({$_ -match [IPAddress]$_ })]  
          [String]$Subnet,
          [Parameter(Position=1)]
          [String]$DNSServer
          )       

    Begin{ 
            
            Write-Verbose "Parameter subnet set to $subnet"
            $octect = $subnet -split "\."
            Write-Verbose "$subnet split into $octect"
         
    }

    Process{
                        
        $range = for ($i = 1; $i -lt 255; $i += 1){
                [PSCustomObject]@{
                    IP = "$($octect.Item(0)).$($octect.Item(1)).$($octect.Item(2)).$($i)"
                    }
        }   
           
        Write-Verbose "Range to be scanned is $($range.ip)"
        
        
        Foreach ($r in $range){
           Write-Verbose "Looking up $($r.IP)"
           Resolve-DnsName $r.IP -Server $DNSServer -Type PTR -ErrorAction SilentlyContinue | 
                where {$_.type -eq 'PTR'} | 
                select Namehost, @{N='Zone'; E={$_.Name}}, @{N='Address'; E={$r.IP}}, Type
        }

       
    } # end process block

} 

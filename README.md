# PowerShell DNS Scripts

DNSCache - Snippets for working with DNS Caching

GetReverseDNS -  Perform a bulk reverse lookup on an entire class C subnet

		Get-ReverseInfo -Subnet '10.33.19.0' -DNSServer 'dnsmaster01.drt01.corp.tripadvisor.com'

ScanDNSonDC - Scan Domain controllers to verify DNS settings are as per best practise

DNSDiag - Get a summary on usage of the DNS server by DNS clients (useful when retiring a DNS server)

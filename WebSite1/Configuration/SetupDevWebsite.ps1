$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword  = $true
         }
        @{
            NodeName                     = "localhost"
            WebsiteName                  = 'website1.domain.net'
            WebsitePath                  = 'C:\inetpub\wwwroot\Website1'
            WebsiteSources               = Resolve-Path $PSScriptRoot\..\SourceCode
            TemporaryFiles               = Join-Path $env:SystemDrive TemporaryFiles
#            CertificateThumbprint        = (get-childitem -Path Cert:\LocalMachine\My | where { $_.subject -eq "CN=localhost" } | Sort-Object -Descending | Select-Object -first 1).Thumbprint
            ConnectionStringsFileName    = "DevConnectionStrings.config"
            ConnectionStringsFileContent = "<?xml version='1.0' encoding='UTF-8'?> 
  <connectionStrings>
    <add name='ConnectionString' 
         connectionString='Integrated Security=SSPI;database=MyDevDatabase;server=MyServer; '/>
  </connectionStrings>"
         }
    )
}

configuration DevWebsite1  
{  
    param  
    (
        [parameter(mandatory)]
        [pscredential] $Credential
    )
    
    Import-DscResource -Module MyCustomResources
    
    Node $AllNodes.NodeName
    {
        DevWebsite devEnvironmentSetup
        {
            WebsiteName                  = $Node.WebsiteName
            WebsitePath                  = $Node.WebsitePath
            WebsiteSources               = $Node.WebsiteSources
            TemporaryFiles               = $Node.TemporaryFiles
            ConnectionStringsFileName    = $Node.ConnectionStringsFileName
            ConnectionStringsFileContent = $Node.ConnectionStringsFileContent
			CertificateThumbprint        = $Node.CertificateThumbprint
            Credential                   = $Credential
        }
    }  
}

DevWebsite1 -ConfigurationData $ConfigData -Output $PSScriptRoot\DevWebsite1 -Credential (Get-Credential) 
Start-DscConfiguration $PSScriptRoot\DevWebsite1 -wait -Verbose -Force

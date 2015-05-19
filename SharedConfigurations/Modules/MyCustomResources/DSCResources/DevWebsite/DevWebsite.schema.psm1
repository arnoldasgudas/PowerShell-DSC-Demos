configuration DevWebsite
{  
    param  
    (
        [parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $WebsiteName,

        [parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $WebsitePath,

        [parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $WebsiteSources,
                
        [string] $TemporaryFiles,
        
        [string] $ConnectionStringsFileName,

        [string] $ConnectionStringsFileContent,

		[string] $CertificateThumbprint,

        [parameter(mandatory)]
        [pscredential] $Credential
    )
     
    Import-DscResource -Module xWebAdministration
    Import-DscResource -Module cWebAdministration
    Import-DscResource -Module rchaganti # HostsFile
    Import-DscResource -Module PowerShellAccessControl

    WindowsFeature IIS  
    {  
        Ensure = "Present"  
        Name   = "Web-Server"  
    }

    WindowsFeature AspNet45  
    {  
        Ensure = "Present"  
        Name   = "Web-Asp-Net45"  
    }

	Package UrlRewrite
	{
		DependsOn = "[WindowsFeature]IIS"
		Ensure    = "Present"
		Name      = "IIS URL Rewrite Module 2"
		Path      = "http://download.microsoft.com/download/6/7/D/67D80164-7DD0-48AF-86E3-DE7A182D6815/rewrite_2.0_rtw_x64.msi"
		Arguments = "/quiet"
		ProductId = "EB675D0A-2C95-405B-BEE8-B42A65D23E11"
	}

    File WebDirectory
    {
        Ensure          = "Present"
        DestinationPath = $WebsitePath
        Force           = $true
        Recurse         = $true
        SourcePath      = $WebsiteSources
        Type            = "Directory"
    }

    File TemporaryFiles
    {
        DestinationPath = $TemporaryFiles
        Type            = "Directory"
        Ensure          = "Present"
    }

    File CreateConnectionStringsConfig 
    {
        DestinationPath = join-path $WebsitePath $ConnectionStringsFileName
        Contents        = $ConnectionStringsFileContent
        Ensure          = "Present"
    } 

    cAccessControlEntry TemporaryFilesPermissions 
    {
        Ensure     = "Present"
        Path       = $TemporaryFiles
        AceType    = "AccessAllowed"
        ObjectType = "Directory"
        AccessMask = ([System.Security.AccessControl.FileSystemRights]::Modify)
        Principal  = $Credential.UserName
    }

    cAccessControlEntry WebDirectoryPermissions 
    {
        Ensure     = "Present"
        Path       = $WebsitePath
        AceType    = "AccessAllowed"
        ObjectType = "Directory"
        AccessMask = ([System.Security.AccessControl.FileSystemRights]::ReadAndExecute)
        Principal  = $Credential.UserName
        DependsOn = "[File]WebDirectory"
    }

    cAccessControlEntry IisUserPermission 
    {
        Ensure     = "Present"
        Path       = $WebsitePath
        AceType    = "AccessAllowed"
        ObjectType = "Directory"
        AccessMask = ([System.Security.AccessControl.FileSystemRights]::ReadAndExecute)
        Principal  = ($env:COMPUTERNAME + '\IIS_IUSRS')
        DependsOn = "[File]WebDirectory"
    }

    cAppPool NewWebsiteAppPool
    {
        Name         = $WebsiteName
        Ensure       = "Present"
        startMode    = "AlwaysRunning"
        identityType = "SpecificUser"
        userName     = $Credential.UserName
        Password     = $Credential
        DependsOn    = "[WindowsFeature]IIS"
    }

    xWebsite NewWebsite   
    {  
        Ensure          = "Present"  
        Name            = $WebsiteName
        State           = "Started"  
        PhysicalPath    = $WebsitePath
        ApplicationPool = $WebsiteName
        DependsOn       = "[cAppPool]NewWebsiteAppPool"
        BindingInfo     = @(
                            @(MSFT_xWebBindingInformation   
                                {  
                                    Protocol              = "HTTP"
                                    Port                  =  80 
                                    HostName              = $WebsiteName
                                }
                            );
#                            @(MSFT_xWebBindingInformation
#                                {
#                                    Protocol              = "HTTPS"
#                                    Port                  = 443
#                                    HostName              = $WebsiteName
#									CertificateThumbprint = $CertificateThumbprint
#									CertificateStoreName  = "WebHosting"
#                                }
#                            )
                          )
    }
   
    HostsFile SetHostsRecord 
    {
        HostName  = $WebsiteName
        IPAddress = "127.0.0.1"
        Ensure    = "Present"
    }
}



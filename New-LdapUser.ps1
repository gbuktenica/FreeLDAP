Function New-LdapUser
{
    <#  
    .SYNOPSIS  
        Create a new LDAP user.

    .DESCRIPTION
        Uses the System.DirectoryServices Assembly to create an LDAP user object in a Non-Microsoft LDAP directory.

    .PARAMETER DistinguishedName
        The distinguished name that will be created.

    .PARAMETER Server
        DNS name or IP address to connect to.

    .PARAMETER Credential
        PSCredential object to bind to LDAP with.

    .PARAMETER SecureSocketLayer
        Forces LDAPS connection

    .PARAMETER TimeOut
        LDAP timeout in seconds.
        Default value 10000 seconds (166 minutes)

    .EXAMPLE
        New-LdapUser -DistinguishedName "cn=Glen,ou=OU,o=Organisation" -Credential $Credential -Server 10.1.1.1
    
    .OUTPUT
        LDAP return codes from LDAP server

    .NOTES  
        Author     : Glen Buktenica
        Version    : 1.0.0.1 20160728 Alpha build 
    #> 
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        [Parameter(Position=0, 
            Mandatory=$true, 
            ValueFromPipeline=$false, 
            ValueFromPipelineByPropertyName=$false)] 
            [string] $DistinguishedName,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string] $Server,
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)] 
            [System.Management.Automation.CredentialAttribute()]
            $Credential,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)] 
            [switch] $SecureSocketLayer,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)] 
            [string] $TimeOut = "10000",
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $Fullname,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $GivenName,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $sn,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $initials,
            [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $logindisabled,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $telephonenumber,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $workforceid,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $managerworkforceid,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $sapposition,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $cn,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $saproles,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $ismanager,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $preferredname,
            [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $sapdateofbirth,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $mail,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $disabledflag,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $title,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [Security.SecureString] $userPassword
    )
    BEGIN 
    {
        Write-Verbose 'Start New-LdapUser'
        $Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree 
        $attrlist = ,"*"
        Write-Verbose "Connecting to Server:"
        Write-Verbose $Server
        Connect-LdapServer -Server $Server -Credential $Credential -ErrorAction Stop
    }
	PROCESS 
    {
        #Get all non manadatory parameters that have a value
        $MandatoryParameters = @("DistinguishedName","Server","Credential","TimeOut","SecureSocketLayer","userPassword") 
        $Keys = (Get-Command -Name $MyInvocation.InvocationName).Parameters.keys
        Write-Output $DistinguishedName
        # Create a new LDAP user request
        $Request = New-Object "System.DirectoryServices.Protocols.AddRequest"
        $Request.DistinguishedName = $DistinguishedName
        [void]$Request.Attributes.Add((New-Object "System.DirectoryServices.Protocols.DirectoryAttribute" -ArgumentList "objectclass",@("person","inetorgperson")))  
        foreach ($Key in $Keys)
        {      
            $Variable = Get-Variable -Name $key -ErrorAction SilentlyContinue
            # Loop through each key that has a value
            # Exclude parameters that are used to set up the LDAP connection
            # Then add the key to the request object
            if($Variable.value.length -gt 0 -and $MandatoryParameters -notcontains $Variable.name)
            {
                Write-Verbose $Variable.name 
                Write-Verbose $Variable.value
                [void]$Request.Attributes.Add((New-Object "System.DirectoryServices.Protocols.DirectoryAttribute" -ArgumentList ($Variable.name),($Variable.value)))
            }
        }

        If ($userPassword.length -gt 0)
        {
            Write-Verbose "Setting Password"
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($userPassword)
            $userPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [void]$Request.Attributes.Add((New-Object "System.DirectoryServices.Protocols.DirectoryAttribute" -ArgumentList userPassword,$userPasswordPlain))
            $userPasswordPlain = $null
            $userPassword = $null
        }
        # This line commits the request object to the LDAP server
        $Result = $global:LdapConnection.SendRequest($Request)   
        Write-Output $Result.ResultCode    
    }
	END 
    {
        Connect-LdapServer -Disconnect
        Write-Verbose 'End New-LdapUser'
    }
}
Export-ModuleMember -function New-LdapUser

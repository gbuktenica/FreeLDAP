Function Remove-LdapUser
{
    <#  
    .SYNOPSIS  
        Removes an LDAP user.

    .DESCRIPTION
        Uses the System.DirectoryServices Assembly to delete an LDAP user object in a Non-Microsoft LDAP directory.

    .PARAMETER DistinguishedName
        The distinguished name that will be removed.

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
        Remove-LdapUser -DistinguishedName "cn=Glen,ou=OU,o=Organisation" -Credential $Credential -Server 10.1.1.1
    
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
            ValueFromPipeline=$true, 
            ValueFromPipelineByPropertyName=$true)] 
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
            [string] $TimeOut = "10000"
    )
    BEGIN 
    {
        Write-Verbose 'Start Remove-LdapUser'
        Write-Verbose "Loading required assemblies"
        Write-Verbose "Connecting to Server:"
        Write-Verbose $Server
        Connect-LdapServer -Server $Server -Credential $Credential -ErrorAction Stop
    }
	PROCESS 
    {
        Write-Output $DistinguishedName
        $Request = New-Object "System.DirectoryServices.Protocols.DeleteRequest"
        $Request.DistinguishedName = $DistinguishedName
        $Result = $global:LdapConnection.SendRequest($Request)   
        Write-Output $Result.ResultCode
    }
	END 
    {
        Connect-LdapServer -Disconnect
        Write-Verbose 'End Remove-LdapUser'
    }
}
Export-ModuleMember -Function Remove-LdapUser

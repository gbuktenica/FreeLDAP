Function Move-LdapUser
{
    <#
    .SYNOPSIS
        Search for User objects in an LDAP directory.

    .DESCRIPTION
        Uses the System.DirectoryServices Assembly to move objects in a Non-Microsoft LDAP directory.

    .PARAMETER Name
        SamAccount or Part of the CN Name to search for..

    .PARAMETER Server
        DNS name or IP address to connect to.

    .PARAMETER Credential
        PSCredential object to bind to LDAP with.

    .PARAMETER SecureSocketLayer
        Forces LDAPS connection

    .PARAMETER TimeOut
        LDAP timeout in seconds.

    .PARAMETER Passthru
        Outputs the connection parameters to the pipeline

    .EXAMPLE
        Get-LdapUser.ps1 -Name bukteng* -Server 10.1.1.1 -Credential (Get-Credential)
        LDAP bind to IP address 10.1.1.1 after prompting the operator for credentials and return all users matching bukteng*

    .OUTPUT
        Distinguished name and other attributes that have values

    .NOTES
        Author     : Glen Buktenica
        Version    : 1.0.0.0 20160704 Initial Build
    #>
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        [Parameter(Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [string[]] $DistinguishedName,
        [Parameter(Position=2,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [string] $Destination,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [string] $Server,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [System.Management.Automation.CredentialAttribute()]
            $Credential,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$false)]
            [switch] $SecureSocketLayer,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$false)]
            [string] $TimeOut = "10000",
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$false)]
            [switch] $PassThru
    )
    BEGIN
    {
        Write-Verbose 'Starting Move-LdapUser'
        Write-Verbose "Loading required assemblies"
        Add-Type -AssemblyName System.DirectoryServices.Protocols -ErrorAction Stop
        Add-Type -AssemblyName System.Net -ErrorAction Stop
        $Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
        $attrlist = ,"*"
        Connect-LdapServer -Server $Server -Credential $Credential -ErrorAction Stop
    }
    PROCESS
    {
        Write-Verbose "Moving $DistinguishedName"
        $ModifyRequest = New-Object "System.DirectoryServices.Protocols.ModifyDNRequest"
        $ModifyRequest.DeleteOldRdn = $true
        $ModifyRequest.DistinguishedName = $DistinguishedName
        $NewName =     $DistinguishedName.Split(",")[0]
        $ModifyRequest.NewName = $NewName
        $ModifyRequest.NewParentDistinguishedName = $Destination
        $Result      = $global:LdapConnection.SendRequest($ModifyRequest)
        $WriteOuput  = $NewName + "," + $Destination
        Write-Output   $WriteOuput
        Write-Output   $Result.ResultCode
        Write-Output   $Result.ErrorMessage
    }
    END
    {
        Connect-LdapServer -Disconnect
        Write-Verbose 'End Move-LdapUser'
    }
}
Export-ModuleMember -function Move-LdapUser
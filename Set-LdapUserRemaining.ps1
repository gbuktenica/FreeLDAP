Function Set-LdapUser
{
    <#
    .SYNOPSIS
        Set attributes on an LDAP user.

    .DESCRIPTION
        Uses the System.DirectoryServices Assembly to Set attributes on an LDAP user object in a Non-Microsoft LDAP directory.

    .PARAMETER DistinguishedName
        The distinguished name that will have attributes edited.
        Value can be piped from Get-LdapUser

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
        Set-LdapUser -DistinguishedName "cn=Glen,ou=OU,o=Organisation" -DisabledFlag "1" -logindisabled "TRUE" -Credential $Credential -Server 10.1.1.1
        Sets the disabled flag to 1 and logindisabled setting to TRUE for LDAP user Glen

    .OUTPUT
        LDAP return codes from LDAP server

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
        [Parameter(Mandatory=$true,
            ValueFromRemainingArguments=$true)]
            [psobject[]]$InputObject
    )
    BEGIN
    {
        Write-Verbose 'Start Set-LdapUser'
        Write-Verbose "Loading required assemblies"
        Add-Type -AssemblyName System.DirectoryServices.Protocols -ErrorAction Stop
        Add-Type -AssemblyName System.Net -ErrorAction Stop
        $Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
        $attrlist = ,"*"
        Write-Verbose "Connecting to Server:"
        Write-Verbose $Server
        Connect-LdapServer -Server $Server -Credential $Credential -ErrorAction Stop
    }
    PROCESS
    {
        Write-Output $DistinguishedName
        foreach($Value in $InputObject)
        {
            Write-Verbose $Value.name
            Write-Verbose $Value.value
            $ModifyRequest = New-Object "System.DirectoryServices.Protocols.ModifyRequest"
            $ModifyRequest.DistinguishedName = $DistinguishedName
            $AttributeModification = New-Object "System.DirectoryServices.Protocols.DirectoryAttributeModification"
            $AttributeModification.Name = $Value.name
            $AttributeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace
            $AttributeModification.Add($Value.value) | Out-Null
            $ModifyRequest.Modifications.Add($AttributeModification) | Out-Null
            $Result = $global:LdapConnection.SendRequest($ModifyRequest)
            Write-Output $Result.ResultCode
        }
    }
    END
    {
        Connect-LdapServer -Disconnect
        Write-Verbose 'End Set-LdapUser'
    }
}
Export-ModuleMember -function Set-LdapUser
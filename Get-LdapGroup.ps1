Function Get-LdapGroup
{
    <#
    .SYNOPSIS
        Search for group objects in an LDAP directory.

    .DESCRIPTION
        Uses the System.DirectoryServices Assembly to search for Group objects in a Non-Microsoft LDAP directory.

    .PARAMETER Name
        The CN Name to search LDAP for.

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
        Get-LdapGroup.ps1 -Name bukteng* -Server 10.1.1.1 -Credential (Get-Credential)
        LDAP bind to IP address 10.1.1.1 after prompting the operator for credentials and return all Groups matching bukteng*

    .OUTPUT
        Distinguished name and other attributes that have values

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
            [string[]] $Name,
        [Parameter(Position=1,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [string] $SearchScope,
        [Parameter(Position=2,
            Mandatory=$true,
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
        Write-Verbose 'Starting Get-LdapGroup'
        $Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
        $attrlist = ,"*"
        Connect-LdapServer -Server $Server -Credential $Credential -ErrorAction Stop
    }
    PROCESS
    {
        Write-Verbose "Searching for $Name"
        $Filter = "(&(cn=$Name)(objectClass=group))"
        $ResponseGroups = New-Object System.DirectoryServices.Protocols.SearchRequest -ArgumentList $SearchScope,$Filter,$Scope,$attrlist
        $ResultGroups = ($global:LdapConnection.SendRequest($ResponseGroups)).Entries
        foreach ($ResultGroup in $ResultGroups)
        {
            #$ResultGroup.Attributes
            $Return = New-Object PSObject
            $Return | Add-Member Noteproperty DistinguishedName ($ResultGroup.DistinguishedName)
            $Keys = $ResultGroup.Attributes.keys
            foreach ($Key in $Keys)
            {
                $Return | Add-Member Noteproperty $Key ($ResultGroup.Attributes.$Key |? {$_}| ForEach-Object {[System.Text.Encoding]::ASCII.GetString($_)})
            }
        }
        If ($Return.length -eq 0)
        {
            Write-Error "$Name not found"
        }
        Else
        {
            $Return
        }
    }
    END
    {
        if (-not $PassThru)
        {
            Connect-LdapServer -Disconnect
        }
        Write-Verbose 'End Get-LdapGroup'
    }
}
Export-ModuleMember -Function Get-LdapGroup
Function Connect-LdapServer
{
    <#  
    .SYNOPSIS  
        Connect to an LDAP server.

    .DESCRIPTION
        Bind to an LDAP server on port 389 using Dot NET class System.DirectoryServices.Protocols 
        and save the connection to the global variable LdapConnection

    .PARAMETER Server
        DNS name or IP address to connect to.

    .PARAMETER Credential
        PSCredential object to bind to the LDAP server with.

    .PARAMETER SecureSocketLayer
        Forces LDAPS connection

    .PARAMETER TimeOut
        LDAP timeout in seconds.
        Default value 10000 seconds (166 minutes)

    .PARAMETER Disconnect
        Disposes the LDAP connection and removes the global variable.

    .PARAMETER DirectoryVersion
        Connects to the LDAP server with a request version of LDAP.
        Defaul value 3

    .EXAMPLE
        Connect-LdapServer -Server 10.1.1.1 -Credential (Get-Credential)
        LDAP bind to IP address 10.1.1.1 after prompting the operator for credentials

    .EXAMPLE
        Connect-LdapServer -Server 10.1.1.1:637 -Credential (Get-Credential)
        LDAP bind to IP address 10.1.1.1 and on port 637 after prompting the operator for credentials

    .EXAMPLE
        Connect-LdapServer -Disconnect
        Disposes the LDAP connection and removes the global variable.

    .NOTES  
        Author     : Glen Buktenica
        Version    : 1.0.0.1 20160801 Alpha Release 1 
    #> 
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)] 
            [ValidateNotNullOrEmpty()] 
            [string] $Server,
        [Parameter(Position=1,
            Mandatory=$false, 
            ValueFromPipeline=$false)] 
            [System.Management.Automation.CredentialAttribute()]
            $Credential,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)] 
            [switch] $SecureSocketLayer,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [string] $TimeOut = "10000",
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [switch] $Disconnect,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false)]
            [int] $DirectoryVersion = 3
    )
    #region Disconnect from LDAP server
    Write-Verbose "Function Connect-LdapServer running"
    If ($Disconnect -and $global:LdapConnection)
    {
        Write-Verbose "Disconnecting from:"
        Write-Verbose $global:LdapConnection.SessionOptions.HostName
        $global:LdapConnection.Dispose()
        Remove-Variable LdapConnection -Scope Global
        return
    }
    Elseif ($Disconnect -and -not $global:LdapConnection)
    {
        Write-Verbose "Nothing to disconnect"
        return
    }
    #endregion Disconnect from LDAP server
    Write-Verbose "Request to connect to $Server"
    Write-Verbose "Loading required assemblies"
    Add-Type -AssemblyName System.DirectoryServices.Protocols -ErrorAction Stop
    Add-Type -AssemblyName System.Net -ErrorAction Stop
    #region Connect to LDAP server
    # If a connection object exists to a different server to the one requested then remove all connection objects.
    if ($global:LdapConnection)
    {
        Write-Verbose "LDAP connection already present to:"
        Write-Verbose $global:LdapConnection.SessionOptions.HostName
        If ($global:LdapConnection.SessionOptions.HostName -ne $Server) 
        {
            Write-Verbose "Existing LDAP connection different to requested connection:"
            Write-Verbose $Server
            Write-Verbose "Disconnecting existing connection:"
            Write-Verbose $global:LdapConnection.SessionOptions.HostName
            $global:LdapConnection.Dispose()
            Remove-Variable LdapConnection -Scope Global
        }
    }
    # If no connection exists then build connection object and bind to LDAP server.
    if (-not $global:LdapConnection)
    {
        Write-Verbose "Connecting to LDAP Server"
        Write-Verbose $Server
        # Count the number of errors in standard error before Try.
        $ErrorCountBefore = $Error.Count
        Try
        {
            $global:LdapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection $Server
            $global:LdapConnection.SessionOptions.SecureSocketLayer = $SecureSocketLayer
            $global:LdapConnection.SessionOptions.ProtocolVersion   = $DirectoryVersion
            $global:LdapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic
            $global:LdapConnection.Timeout = $TimeOut
            $global:LdapConnection.Bind($Credential)
        }
        Catch
        {
            # If connection fails then remove all connection objects.
            Write-Error "Could not bind to LDAP server"
            $global:LdapConnection.Dispose()
            Remove-Variable LdapConnection -Scope Global
        }
        # If the number of standard errors before the Try is the same as after the Try then connection was successfull.
        $ErrorCountAfter = $Error.Count
        If ($ErrorCountBefore -eq $ErrorCountAfter)
        {
            Write-Verbose "Connection successful"
        }
    }
    #endregion Connect to LDAP server
}
Export-ModuleMember -function Connect-LdapServer

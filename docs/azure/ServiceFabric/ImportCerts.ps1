#Specify the password of the pfx files.
$password = "localhost"
# Specify the list of pfx files want to be imported
$PfxFiles ="./localhost.pfx","./localhost.pfx"
# Specfiy the Service account that the cert will be granted to
$serviceAccount= "NETWORK SERVICE"
# The store of certs
$CertStoreLocation ="Cert:\LocalMachine\My"

# DONOT changes the below commands.
$securePassword = ConvertTo-SecureString -String $password -Force –AsPlainText;

$PfxFiles.ForEach{

    write-host "Import $_";
    $cert = Import-PfxCertificate -Exportable -CertStoreLocation $CertStoreLocation -FilePath $_ -Password $securePassword;

    write-host "Grant permission on $_ to $serviceAccount";

    # Specify the user, the permissions, and the permission type
    $permission = "$($serviceAccount)","FullControl","Allow"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission

    # Location of the machine-related keys
    $keyPath = Join-Path -Path $env:ProgramData -ChildPath "\Microsoft\Crypto\RSA\MachineKeys"
    $keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $keyFullPath = Join-Path -Path $keyPath -ChildPath $keyName

    # Get the current ACL of the private key
    $acl = (Get-Item $keyFullPath).GetAccessControl('Access')

    # Add the new ACE to the ACL of the private key
    $acl.SetAccessRule($accessRule)

    # Write back the new ACL
    Set-Acl -Path $keyFullPath -AclObject $acl -ErrorAction Stop

    # Observe the access rights currently assigned to this certificate
    get-acl $keyFullPath| fl
}

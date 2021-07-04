#############################################################
# Created By: Daniel Wroe                                   #
# Date: 04/07/2021                                          #
# Description: Script to create VPN certificates for an     #
#              Azure P2S VPN                                #
#############################################################

## Update variables below to match your environment
## Create a comma seperated array of users to create certificats for
$users = "user1","user2"                                ## An Array of users for who you want to create certificates for
$PFXPassword = "Password1"                              ## The password to import the PFX certificate
$workingPath = "C:\temp"                                ## A directory to store the PFX certificates and VPN installation files
$VPNGatewayName = "VPNGwDemo-GW"                        ## The VPN Gateway name that we will be creating users for
$resourceGroup = "VPNGwDemo"                            ## Resource Group where VPN Gateway is located
$subscriptionId = "000000-0000000-000000-000000"        ## The subscription ID for your Azure Subscription where the VPN Gateway is deployed

Login-AzAccount
Select-AzSubscription -subscriptionId $subscriptionId

## Create Directory to store assets if it doesnt already exist
If(!(test-path $workingPath))
{
      New-Item -ItemType Directory -Force -Path $workingPath
}

foreach ($user in $users) {
    ## A friendly Name for the person or device we are generating the certificate for
    $name = $user

    ## Create a variable with a canonical name for the certificate
    $who = "CN=" + $name 

    ## Create a canonical name for the Root Certificate
    $rca = $who + "ROOT"

    ## Define a password for the the PFX file
    $pw = ConvertTo-SecureString -String $PFXPassword  –asplaintext –force 

    ## Create Root Certificate
    $rootcert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject $rca -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

    ## Create Client Cert based off the Root Certificate
    $clientcert = New-SelfSignedCertificate -Type Custom -DnsName $name -KeySpec Signature -Subject $who -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\CurrentUser\My" -Signer $rootcert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

    ## Export the client Certificate
    Export-PFXCertificate -Password $pw -Cert $clientcert -FilePath $workingPath\$name.pfx

    ## Get the base64 hash data of the Root certificate
    $CertBase64_3 = [system.convert]::ToBase64String($rootcert.RawData)

    ## Upload the Public Root certificate to the VPN Gateway
    Add-AzVpnClientRootCertificate -VpnClientRootCertificateName $name -VirtualNetworkGatewayName $VPNGatewayName -ResourceGroupName $resourceGroup -PublicCertData $CertBase64_3

}

## Download the VPN client 
$vpnclient = New-AzVpnClientConfiguration -ResourceGroupName $resourceGroup -name $VPNGatewayName -AuthenticationMethod "EapTls"
wget $vpnclient.VpnProfileSASUrl -OutFile $workingPath\vpnclient.zip
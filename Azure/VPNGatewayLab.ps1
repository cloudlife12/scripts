#############################################################
# Created By: Dan - Cloudlife.co.uk                         #
# Date: 04/07/2021                                          #
# Description: Script to create a VPN Gateway Lab           #
# Note: This script can take up to 1 hour to privision the  #
#       VPN Gateway                                         #
#############################################################

## Define Variables
$rg = "VPNGwDemo"                                       ## The resource group name you want to store all the resources in
$location = "uksouth"                                   ## The region you want to deploy resources to
$vnetname = "VPNGWDemo-VNET"                            ## The name you want to be displayed for the Virtual Network in Azure
$VNETAddressSpace = "10.0.0.0/16"                       ## The IP Scope of the Virtual Network - This must be at least a /23 to accomodate the main subnet and gateway subnet
$subnet1Name = "InternalServers"                        ## A friendly name to refer to the network segment
$subnet1AddressSpace = "10.0.0.0/24"                    ## The address space to be used for your internal resources
$gatewaySubnetAddressSpace = "10.0.1.0/24"              ## The address space to be used for the GatewaySubnet
$publicIPResourceName = "VPNGwDemo-PIP"                 ## The name you want to be displayed for the Public IP resource in Azure
$VPNGatewayName = "VPNGwDemo-GW"                        ## The name you want to be displayed for the VPN gateway resource in Azure
$VPNClientIPAddressPool = "172.16.0.0/24"               ## The IP range that will be assigned to clients when connected to the VPN
$subscriptionId = "000000-0000000-000000-000000"        ## The subscription ID for your Azure Subscription where the VPN Gateway is deployed

Login-AzAccount
Select-AzSubscription -subscriptionId $subscriptionId

# Create Resource Group
New-AzResourceGroup -Location uksouth -Name $rg

# Create Virtual Network
$vnet = New-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rg -Location $location -AddressPrefix $VNETAddressSpace

# Create internal use subnet
Add-AzVirtualNetworkSubnetConfig -name $subnet1Name -VirtualNetwork $vnet -AddressPrefix $subnet1AddressSpace
$vnet | Set-AzVirtualNetwork

# Create GatewaySubnet for the VPN Gateway to reside in
Add-AzVirtualNetworkSubnetConfig -name "GatewaySubnet" -VirtualNetwork $vnet -AddressPrefix $gatewaySubnetAddressSpace
$vnet | Set-AzVirtualNetwork

# Create a public IP Address for the VPN gateway
$vpngwpip = New-AzPublicIpAddress -Name $publicIPResourceName -ResourceGroupName $rg -Location $location -AllocationMethod Dynamic

# Update the VNET variable with the updated settings
$vnet = Get-AzVirtualNetwork -Name $vnetname

# Get the GatewaySubnet
$subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

# Create an IP config with containing the public IP
$vpngwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name vpngwipconfig -SubnetId $subnet.Id -PublicIpAddressId $vpngwpip.Id

# Create VPN Gateway
New-AzVirtualNetworkGateway -Name $VPNGatewayName -ResourceGroupName $rg -Location $location -IpConfigurations $vpngwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Basic

# Store the VPN Gateway object
$vpngw = Get-AzVirtualNetworkGateway -name $VPNGatewayName -ResourceGroupName $rg

# Enabled the P2S VPN functionality and sets the P2S VPN client pool 
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $vpngw -VPNClientAddressPool $VPNClientIPAddressPool




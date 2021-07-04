#############################################################
# Created By: Daniel Wroe                                   #
# Date: 04/07/2021                                          #
# Description: Script to create a VPN Gateway Lab           #
#############################################################

# Define Variables
$rg = "VPNGwDemo"
$location = "uksouth"
$vnetname = "VPNGWDemo-VNET"
$VNETAddressSpace = "10.0.0.0/16"
$subnet1Name = "InternalServers"
$subnet1AddressSpace = "10.0.0.0/24"
$gatewaySybnetName = "GatewaySubnet"
$gatewaySubnetAddressSpace = "10.0.1.0/24"
$publicIPResourceName = "VPNGwDemo-PIP"
$VPNGatewayName = "VPNGwDemo-GW"
$VPNClientIPAddressPool = "172.16.0.0/24"

# Create Resource Group
New-AzResourceGroup -Location uksouth -Name $rg

# Create Virtual Network
$vnet = New-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rg -Location $location -AddressPrefix $VNETAddressSpace

# Create internal use subnet
Add-AzVirtualNetworkSubnetConfig -name $subnet1Name -VirtualNetwork $vnet -AddressPrefix $subnet1AddressSpace
$vnet | Set-AzVirtualNetwork

# Create GatewaySubnet for the VPN Gateway to reside in
Add-AzVirtualNetworkSubnetConfig -name $gatewaySybnetName -VirtualNetwork $vnet -AddressPrefix $gatewaySubnetAddressSpace
$vnet | Set-AzVirtualNetwork

# Create a public IP Address for the VPN gateway
$vpngwpip = New-AzPublicIpAddress -Name $publicIPResourceName -ResourceGroupName $rg -Location $location -AllocationMethod Dynamic

# Update the VNET variable with the updated settings
$vnet = Get-AzVirtualNetwork -Name $vnetname

# Get the GatewaySubnet
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $gatewaySybnetName -VirtualNetwork $vnet

# Create an IP config with containing the public IP
$vpngwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name vpngwipconfig -SubnetId $subnet.Id -PublicIpAddressId $vpngwpip.Id

# Create VPN Gateway
New-AzVirtualNetworkGateway -Name $VPNGatewayName -ResourceGroupName $rg -Location $location -IpConfigurations $vpngwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Basic


$vpngw = Get-AzVirtualNetworkGateway -name $VPNGatewayName -ResourceGroupName $rg

Set-AzVirtualNetworkGateway -VirtualNetworkGateway $vpngw -VPNClientAddressPool $VPNClientIPAddressPool




# Do "az login --use-device-code" first

$rg = "rg-tcdemo-vsprof-001"
$vm = "vmteamcity001"
$nsg = $vm + "nsg"
$image = "Win2019Datacenter"
$size = "Standard_B2ms"
#$spotVmMaxPricePerHr = 0.1
$publicIP = $vm + "PublicIP"
$dnsName = "vmteamcity001" # DNS will be vmteamcity001.northcentralus.cloudapp.azure.com"

& az group create -n $rg -l northcentralus

$admin = Get-Credential -Message "Enter new VM admin user credentials"
& az vm create `
    --resource-group $rg `
    --name $vm `
    --image $image `
    --admin-username $admin.GetNetworkCredential().UserName `
    --admin-password $admin.GetNetworkCredential().Password `
    --size $size
    #--priority Spot ` # Spot instances not available at that location :(
    #--max-price $spotVmMaxPricePerHr `
    #--eviction-policy Deallocate

# Remove default "RDP open to everyone rule"
& az network nsg rule delete -g $rg --nsg $nsg --name rdp

# What's my public IP
$ip = curl "https://api.ipify.org?format=json" | ConvertFrom-Json | select -ExpandProperty ip

& az network nsg rule create `
    -g $rg `
    --nsg-name $nsg `
    -n "RDP Inbound 1" `
    --priority 1000 `
    --source-address-prefixes $ip `
    --destination-address-prefixes '*' `
    --destination-port-ranges 3389 `
    --access Allow `
    --protocol Tcp `
    --description "Allow inbound RDP from my IP."

& az network nsg rule create `
    -g $rg `
    --nsg-name $nsg `
    -n "Allow http" `
    --priority 100 `
    --source-address-prefixes '*' `
    --destination-address-prefixes '*' `
    --destination-port-ranges 80 `
    --access Allow `
    --protocol Tcp `
    --description "Allow http."

& az network public-ip update `
    -g $rg `
    -n $publicIP `
    --dns-name $dnsName `
    --allocation-method Dynamic
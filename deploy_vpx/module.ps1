# Usage: pwsh module.ps1 -vmname <vm-name> -vserverip <vserverip> -vserveruser <vserveruser> -vserverpass <vserverpass> -networkname <networkname>
param (
    [string] $vmname = $null,
    [string] $vserverip = $null,
    [string] $vserveruser = $null,
    [string] $vserverpass = $null,
    [string] $networkname = $null
)

function Add-A-Property($vm, $propKey, $propId, $propLabel, $propType, $propDefaultValue) {
    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.vAppConfig = New-Object VMware.Vim.VmConfigSpec
    $spec.vAppConfig.property = New-Object VMware.Vim.VAppPropertySpec[] (1)
    $spec.vAppConfig.property[0] = New-Object VMware.Vim.VAppPropertySpec
    $spec.vAppConfig.property[0].operation = "add"
    $spec.vAppConfig.property[0].info = New-Object VMware.Vim.VAppPropertyInfo
    $spec.vAppConfig.property[0].info.key = $propKey
    $spec.vAppConfig.property[0].info.id = $propId
    $spec.vAppConfig.property[0].info.label = $propLabel
    $spec.vAppConfig.property[0].info.type = $propType
    $spec.vAppConfig.property[0].info.defaultValue = $propDefaultValue

    $vm.ExtensionData.ReconfigVM_Task($spec)
}

if (Get-Module -ListAvailable -Name VMware.PowerCLI) {
    Write-Host "VMWare.PowerCLI Module exists"
}
else {
    Write-Host "VMWare.PowerCLI Module does not exist. Installing"
    Install-Module VMware.PowerCLI -Repository PSGallery -Force
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false

Connect-VIServer -Server $vserverip -Username $vserveruser -Password $vserverpass

$myvm = Get-VM -Name $vmname

write-output "Stopping VM " $vmname
start-sleep -s 60
Stop-vm -VM $myvm -Confirm:$false

write-output "Modifying vApp properties for VM " $vmname
start-sleep -s 60


write-output "Changing IP_ALLOCATION_POLICY to STTIC_IPPOOL"
$spec1 = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec1.vAppConfig = New-Object VMware.Vim.VmConfigSpec
$spec1.vAppConfig.ipAssignment = New-Object VMware.Vim.VAppIPAssignmentInfo
$spec1.VAppConfig.IpAssignment.IpAllocationPolicy = "fixedAllocatedPolicy"
$myvm.ExtensionData.ReconfigVM_Task($spec1)


write-output "vApp Properties being added for VM: " $vmname
Add-A-Property $myvm 0 "eth0.ipAddress" "ipAddress" "expression" "`${autoIp:$networkname}"
Add-A-Property $myvm 1 "eth0.subnetMask" "subnetMask" "expression" "`${netmask:$networkname}"
Add-A-Property $myvm 2 "eth0.gatewayAddress" "gatewayAddress" "expression" "`${gateway:$networkname}"
Add-A-Property $myvm 3 "eth0.connectivityType" "ipAddress" "string" 'mgmt'

write-output "vApp Properties added. Waiting to start VM " $vmname
start-sleep -s 60

Start-vm -VM $myvm -Confirm:$false


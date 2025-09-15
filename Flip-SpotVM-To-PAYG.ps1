<#
.SYNOPSIS
    Converts a Spot Azure VM to a Pay-As-You-Go (PAYG) VM using the existing NIC, OS disk, and data disks.

.DESCRIPTION
    This script deallocates and deletes a Spot VM in Azure while preserving the NIC and disks. It then recreates the VM as a PAYG instance using the same OS and data disk resources.

.PARAMETER ResourceGroupName
    The name of the Azure Resource Group.

.PARAMETER VMName
    The name of the existing Spot VM and new PAYG VM.

.PARAMETER Location
    The Azure region (e.g., westus, eastus2).

.PARAMETER NICName
    The name of the existing network interface card (NIC).

.PARAMETER OSDiskName
    The name of the existing managed OS disk.

.PARAMETER DataDiskName
    The name of the existing managed data disk (optional).

.PARAMETER VMSize
    The VM SKU to use for the new PAYG VM (e.g., Standard_B2ls_v2).

.EXAMPLE
    .\Flip-SpotVM-To-PAYG.ps1 `
        -ResourceGroupName "myResourceGroup" `
        -VMName "myVm01" `
        -Location "westus" `
        -NICName "myVm01-nic" `
        -OSDiskName "myVm01-osDisk" `
        -DataDiskName "myVm01-dataDisk" `
        -VMSize "Standard_B2ls_v2"

.NOTES
    Author: Shannon Eldridge-Kuehn
    Date: September 14, 2025
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $VMName,

    [Parameter(Mandatory = $true)]
    [string] $Location,

    [Parameter(Mandatory = $true)]
    [string] $NICName,

    [Parameter(Mandatory = $true)]
    [string] $OSDiskName,

    [Parameter(Mandatory = $false)]
    [string] $DataDiskName,

    [Parameter(Mandatory = $true)]
    [string] $VMSize
)

Write-Output "=== Starting Spot to PAYG conversion for VM: $VMName ==="

# Retrieve existing resources
Write-Output "Fetching OS disk..."
$osDisk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $OSDiskName

Write-Output "Fetching NIC..."
$nic = Get-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName

if ($DataDiskName) {
    Write-Output "Fetching data disk..."
    $dataDisk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DataDiskName
}

# Stop and delete the Spot VM
Write-Output "Stopping VM: $VMName..."
Stop-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName -Force -ErrorAction Stop

Write-Output "Deleting Spot VM (preserving NIC and disks)..."
Remove-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName -Force -ErrorAction Stop

# Build new VM config
Write-Output "Configuring new PAYG VM..."
$vmConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize

# Attach existing OS disk
$vmConfig = Set-AzVMOSDisk -VM $vmConfig `
    -ManagedDiskId $osDisk.Id `
    -CreateOption Attach `
    -Windows

# Attach NIC
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Set Trusted Launch security profile
Write-Output "Setting Trusted Launch security profile..."
$securityProfile = New-Object -TypeName Microsoft.Azure.Management.Compute.Models.SecurityProfile
$securityProfile.SecurityType = "TrustedLaunch"
$vmConfig.SecurityProfile = $securityProfile

# Attach data disk if provided
if ($DataDiskName) {
    Write-Output "Attaching data disk..."
    $vmConfig = Add-AzVMDataDisk -VM $vmConfig `
        -Name $DataDiskName `
        -CreateOption Attach `
        -ManagedDiskId $dataDisk.Id `
        -Lun 1
}

# Deploy new PAYG VM
Write-Output "Creating PAYG VM..."
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig -ErrorAction Stop

Write-Output "=== PAYG VM '$VMName' created successfully in resource group '$ResourceGroupName' ==="

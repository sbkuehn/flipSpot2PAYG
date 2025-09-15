# Flip Azure Spot VM to PAYG (PowerShell Script)

This PowerShell script allows you to convert a Spot VM in Azure to a PAYG (Pay-As-You-Go) VM using the same OS disk, data disk, and network interface. This can be useful if your Spot VM is evicted or you decide to switch to a more reliable pricing model.

---

## 🔧 What It Does

- Deallocates and deletes the existing Spot VM (keeping disks and NIC intact)
- Reuses:
  - The OS disk
  - The data disk (optional)
  - The original network interface
- Creates a new VM with:
  - Standard security profile (Trusted Launch disabled)
  - No public IP
  - Lower-cost PAYG VM size (example: `Standard_B2ls_v2`)

---

## 🚀 How to Use

1. Edit the script variables:
   - `resourceGroup`
   - `location`
   - `newVmName`
   - `osDiskName`
   - `dataDiskName`
   - `nicName`

2. Run the script in **Azure PowerShell**.

> 💡 Be sure the original OS disk is Gen2 and supports the selected size/region.

---

## ✅ Prerequisites

- Azure PowerShell (`Az` module)
- Contributor or higher role on the resource group
- Disks and NIC must still exist

---

## 📎 Example

```powershell
$resourceGroup = "myResourceGroup"
$newVmName = "myVm01"
$location = "westus"
$nicName = "myVm01-nic"
$vmSize = "Standard_B2ls_v2"
$osDiskName = "myVm01-osDisk"
$dataDiskName = "myVm01-dataDisk"

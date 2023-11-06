<#
.SYNOPSIS
    This PowerShell module provides cmdlets for setting tag vsanWitness at vmkernel interface on particular VMware ESXi host. This tag is allows to force vSAN Witness traffic to use particular vmkernel adapter.
.DESCRIPTION
    The PowerCLIHackathon module allows you to setup tag vsanWitness at vmkernel interface on particular VMware ESXi host using PowerShell. To use this module, you must first connect to a vCenter server using the Connect-VIServer cmdlet. Once connected, you can use the Get-VMHost cmdlet to retrieve a list of VMHosts, and then pipe the output to that cmdlet Set-vSANWitnessTag to perform setting tag on vmkernel adapter. vmkernel interface name is mandatory.
.PARAMETER VMKernelInterface
    Specifies the name of the VMkernel interface to use when piping to a VMHost object.
.EXAMPLE
    This example retrieves a particular ESXi host object and setting vmk2 interface for vSAN Witness traffic :
    PS C:\> Connect-VIServer -Server vcenter.example.com
    PS C:\> get-vmhost -Name labesx002.soultec.lab | Set-vSANWitnessTag -vmKernelInterface "vmk2"
#>

# Module manifest for module 'PowerCLIHackathon'
$ModuleManifest = @{
    ModuleVersion     = '1.1'
    Guid              = 'e4e602be-36cd-4a16-b922-a3ff78f09e7e'
    Author            = 'Dario Doerflinger'
    CompanyName       = 'VMwareExploreHackathon2023Team6'
    Copyright         = '(c) 2023 Hackathon. All rights reserved.'
    Description       = 'Tag VMkernel Interfaces with the vSANWitness tag'
    FunctionsToExport = @('Set-vSANWitnessTag')
    VariablesToExport = '*'
    CmdletsToExport   = '*'
}

# Private function to perform a specific task
function Set-vSANWitnessTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$VMHostObject,

        [Parameter(Mandatory = $true)]
        [string] $vmKernelInterface
    )

    process {
        #check for esxi version
        #$pattern = "^(8\.0\.2|[89]\.\d+\.\d+|\d+\.\d+\.\d+)$"
        $version = $VMHostObject.Version
        $version = $version.Replace(".", "")
        $versionint = [int]$version

        #Write-Host "VMHost: $($VMHostObject.Name), String: $vmKernelInterface"
        if ($versionint -ge 802) {
            #host version is higher than 8.0.2
            $esxiView = $VMHostObject | Get-View
            $nicManager = Get-View -Id $esxiView.Configmanager.VirtualNicManager
            $nicManager.SelectVnicForNicType("vsanWitness", $vmKernelInterface)

        }
        else {
            #host version is lower than 8.0.2
            $esxcli = Get-EsxCli -VMHost $VMHostObject -V2
            $esxcli.network.ip.interface.tag.add.Invoke(@{tagname = "VSANWitness"; interfacename = "$vmKernelInterface" })

        }

    }
}

function Remove-vSANWitnessTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$VMHostObject,

        [Parameter(Mandatory = $true)]
        [string] $vmKernelInterface
    )

    process {
        #check for esxi version
        #$pattern = "^(8\.0\.2|[89]\.\d+\.\d+|\d+\.\d+\.\d+)$"
        $version = $VMHostObject.Version
        $version = $version.Replace(".", "")
        $versionint = [int]$version

        #Write-Host "VMHost: $($VMHostObject.Name), String: $vmKernelInterface"
        if ($versionint -ge 802) {
            #host version is higher than 8.0.2
            $esxiView = $VMHostObject | Get-View
            $nicManager = Get-View -Id $esxiView.Configmanager.VirtualNicManager
            $nicManager.DeselectVnicForNicType("vsanWitness", "$vmKernelInterface")
        }
        else {
            #host version is lower than 8.0.2
            $esxcli = Get-EsxCli -VMHost $VMHostObject -V2
            $esxcli.network.ip.interface.tag.remove.Invoke(@{tagname = "VSANWitness"; interfacename = "$vmKernelInterface" })
        }
    }
}

Export-ModuleMember -Function * -Variable *

## Dot-source the module manifest to export the module members
$PSCmdlet.MyInvocation.MyCommand.Module.PrivateData = $ModuleManifest

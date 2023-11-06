# Module manifest for module 'PowerCLIHackathon'
$ModuleManifest = @{
    ModuleVersion     = '1.0'
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
            $esxcli = Get-EsxCli -VMHost $VMHostObject | Out-Null
            Try {
                sleep 1
                $esxcli.network.ip.interface.tag.add($vmKernelInterface, "VSANWitness")
                sleep 1
                $esxcli.network.ip.interface.tag.get($vmKernelInterface) 
            }
            Catch {
                Write-Warning "$($VMHostObject.Name) - could not tag interface"
            }
        }

    }
}

Export-ModuleMember -Function * -Variable *

# Dot-source the module manifest to export the module members
$PSCmdlet.MyInvocation.MyCommand.Module.PrivateData = $ModuleManifest

using module ..\..\Classes\Fabric.psm1
using module ..\..\Classes\Network.psm1

function Get-FabricUplinkPayload($Name, $Description, $MediaType, $Ports, $NetworkIds, $UnTaggedNetwork, $UplinkFailureDetection) {
    $Payload = '{
        "Name": "Uplink_Ethernet_Fabric-B",
        "Description": "Ethernet Uplink created from REST.",
        "MediaType": "Ethernet",
        "NativeVLAN": 0,
        "UfdEnable":"Disabled",
        "Ports": [
            {
                "Id": "6ZB1XC2:ethernet1/1/41"
            },
            {
                "Id": "5ZB1XC2:ethernet1/1/41"
            }
        ],
        "Networks": [
            {
                "Id": 95614
            }
        ]
    }' | ConvertFrom-Json

    $Payload.Name = $Name
    $Payload.Description = $Description
    $Payload.MediaType = $MediaType
    if ($null -eq $UnTaggedNetwork) {
        $Payload.NativeVLAN = 0
    } else {
        $Payload.NativeVLAN = $UnTaggedNetwork.VlanMaximum
    }
    
    if ($UplinkFailureDetection) {
        $Payload.UfdEnable = "Enabled"
    }

    $PortPayloads = @()
    $PortSplit = @()
    if ($null -ne $Ports) {
        $PortSplit = $($Ports.Split(",") | % { $_.Trim() })
    }
    foreach ($Port in $PortSplit) {
        if ($Port -ne "") {
            $PortPayload = '{
                "Id": ""
            }' | ConvertFrom-Json
            $PortPayload.Id = $Port
            $PortPayloads += $PortPayload
        }
    }

    $NetworkPayloads = @()
    foreach ($NetworkId in $NetworkIds) {
        $NetworkPayload = '{
            "Id": ""
        }' | ConvertFrom-Json
        $NetworkPayload.Id = $NetworkId
        $NetworkPayloads += $NetworkPayload
    }

    $Payload.Ports = $PortPayloads
    $Payload.Networks = $NetworkPayloads

    $Payload = $Payload | ConvertTo-Json -Depth 6
    return $Payload
}

function New-OMEFabricUplink {
<#
Copyright (c) 2023 Dell EMC Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
 .SYNOPSIS
   Create an MCM group 

 .DESCRIPTION
   This script uses the OME REST API to create mcm group, find memebers and add the members to the group.

 .PARAMETER FabricName
   The Name of the MCM Fabric.

 .EXAMPLE
   New-OMEFabric -FabricName TestFabric -Wait

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String] $Name,

    [Parameter(Mandatory=$false)]
    [String] $Description,

    [Parameter(Mandatory)]
    [Fabric] $Fabric,

    [Parameter(Mandatory)]
    [ValidateSet("Ethernet - No Spanning Tree", "Ethernet", "FCoE", "FC Gateway", "FC Direct Attach")]
    [String]$UplinkType,

    [Parameter(Mandatory=$false)]
    [Switch]$UplinkFailureDetection,

    [Parameter(Mandatory)]
    [String] $Ports,
    
    [Parameter(Mandatory=$false)]
    [Network[]] $TaggedNetworks,

    [Parameter(Mandatory=$false)]
    [Network] $UnTaggedNetwork
)

## Script that does the work
if (!$(Confirm-IsAuthenticated)){
    Return
}

Try {
    if ($SessionAuth.IgnoreCertificateWarning) { Set-CertPolicy }
    $BaseUri = "https://$($SessionAuth.Host)"
    $Headers = @{}
    $Headers."X-Auth-Token" = $SessionAuth.Token
    $ContentType = "application/json"

    $TaggedNetworkIds = @()
    foreach ($Network in $TaggedNetworks) {
        $TaggedNetworkIds += $Network.Id
    }
    Write-Verbose "Creating fabric uplink"
    $FabricPayload = Get-FabricUplinkPayload -Name $Name -Description $Description -MediaType $UplinkType -Ports $Ports `
        -NetworkIds $TaggedNetworkIds -UnTaggedNetwork $UnTaggedNetwork -UplinkFailureDetection $UplinkFailureDetection
    Write-Verbose $FabricPayload
    $CreateFabricUplinkURL = $BaseUri + "/api/NetworkService/Fabrics('$($Fabric.Id)')/Uplinks"
    Write-Verbose $CreateFabricUplinkURL
    $Response = Invoke-WebRequest -Uri $CreateFabricUplinkURL -UseBasicParsing -Headers $Headers -ContentType $ContentType -Method POST -Body $FabricPayload 
    if ($Response.StatusCode -in 200, 201) {
        $UplinkId = $Response.Content | ConvertFrom-Json
        Write-Verbose "Created fabric uplink successfully...UplinkId is $($UplinkId)"
        return $UplinkId
    }
    else {
        Write-Warning "Failed to create fabric uplink"
    }
}
catch {
    Resolve-Error $_
}

}
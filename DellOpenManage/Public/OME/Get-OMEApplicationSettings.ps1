﻿function Get-OMEApplicationSettings {
    <#
Copyright (c) 2018 Dell EMC Corporation

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
    Refresh inventory on devices in OpenManage Enterprise
.DESCRIPTION
    This will submit a job to refresh the inventory on provided Devices.
.PARAMETER Name
    Name of the inventory refresh job
.PARAMETER Devices
    Array of type Device returned from Get-OMEDevice function.
.INPUTS
    Device
.EXAMPLE
    "PowerEdge R640" | Get-OMEDevice -FilterBy "Model" | Invoke-OMEInventoryRefresh -Verbose
    Create separate inventory refresh job for each device in list
.EXAMPLE
    ,$("PowerEdge R640" | Get-OMEDevice -FilterBy "Model") | Invoke-OMEInventoryRefresh -Verbose
    Create one inventory refresh job for all devices in list. Notice the preceeding comma before the device list.
#>

    [CmdletBinding()]
    param(
    )

    Begin {}
    Process {
        if (!$(Confirm-IsAuthenticated)) {
            Return
        }
        Try {
            if ($SessionAuth.IgnoreCertificateWarning) { Set-CertPolicy }
            $BaseUri = "https://$($SessionAuth.Host)"
            $Type = "application/json"
            $Headers = @{}
            $Headers."X-Auth-Token" = $SessionAuth.Token

            $JobURL = $BaseUri + "/api/ApplicationService/Actions/ApplicationService.GetConfiguration"
            $JobResp = Invoke-WebRequest -Uri $JobURL -UseBasicParsing -Headers $Headers -ContentType $Type -Method POST -Body $null
            if ($JobResp.StatusCode -eq 200) {
                Write-Verbose "Application settings job submitted successful..."
                $JobInfo = $JobResp.Content | ConvertFrom-Json
                $JobInfo
            }
            else {
                Write-Error "Job creation failed"
            }
        }
        Catch {
            Resolve-Error $_
        }
    }

    End {}

}
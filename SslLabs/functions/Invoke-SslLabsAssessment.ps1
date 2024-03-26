function Invoke-SslLabsAssessment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $HostName,

        [switch]
        $Publish,

        [switch]
        $IgnoreCertificate
    )
    
    begin
    {
        $VerbosePreference = "SilentlyContinue"
        Test-SslLabsApi

        $Splat = $PSBoundParameters
        $null = $Splat.Remove("HostName")
        $Splat["Method"] = "Get"
        $Splat["Uri"] = "$ApiBase/analyze"
        $Splat["Body"] = @{
            startNew = "on"
            all = "done"
        }
    }
    
    process
    {
        $Splat["Body"]["host"] = $HostName
        $baseID = 10
        Write-Progress -Activity "Testing SSL configuration for host: [$HostName]" -Id 1
        $Response = Invoke-RestMethod @Splat
        $null = $Splat["Body"].Remove("startNew")
        do
        {
            $Response = Invoke-RestMethod @Splat
            foreach ($Endpoint in $Response.endpoints)
            {
                $Index = $Response.endpoints.ipAddress.indexof($Endpoint.ipAddress)
                $ProgressSplat = @{
                    Activity = "Testing endpoint $($Endpoint.ipAddress)"
                    CurrentOperation = $Response.statusDetailsMessage
                    PercentComplete = $Endpoint.progress
                    ParentId = 1
                    Id = $Index + $baseID
                }
                Write-Progress @ProgressSplat
            }
            Start-Sleep -Seconds 1
        }
        until
        (
            $Response.Status -eq "READY"
        )

        $Response
    }
}

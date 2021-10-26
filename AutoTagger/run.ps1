param($eventGridEvent, $TriggerMetadata)

# Make sure to pass hashtables to Out-String so they're logged correctly
#$eventGridEvent | Out-String | Write-Host

# uncomment for claims detail for debugging
#Write-Output $eventGridEvent.data.claims | Format-List

$name = $eventGridEvent.data.claims.name
Write-Output "NAME: $name"

$appid = $eventGridEvent.data.claims.appid
Write-Output "APPID: $appid"

$email = $eventGridEvent.data.claims.'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
Write-Output "EMAIL: $email"

$time = Get-Date -Format "MM/dd/yyyy"
Write-Output "TIMESTAMP: $time"

$uri = $eventGridEvent.data.resourceUri
Write-Output "URI: $uri"


try {
    $resource = Get-AzResource -ResourceId $uri -ErrorAction Stop

    If (($resource) -and
        ($resource.ResourceId -notlike '*Microsoft.Resources/deployments*')) {

        Write-Output 'Attempting to tag resource'


        $tags = @{
            "LastModifiedBy"        = $name
            "LastModifiedTime"      = $time
        }
        try {
            Update-AzTag -ResourceId $uri -Tag $tags -Operation Merge
        }
        catch {
            Write-Output "Encountered error writing tag, may be a resource that does not support tags."
        }
    }
    else {
        Write-Output 'Excluded resource type'
    }
}
catch {
    Write-Output "Not able query the resource Uri. This could be due to a permissions problem (identity needs reader); or not a resource we can query"
}



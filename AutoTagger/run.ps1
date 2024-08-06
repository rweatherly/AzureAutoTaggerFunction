param($eventGridEvent, $TriggerMetadata)

# Make sure to pass hashtables to Out-String so they're logged correctly
$eventGridEvent | Out-String | Write-Host

# Import the necessary modules
Import-Module Az.Accounts -Force
Import-Module Az.Resources -Force
#Import-Module SqlServer -Force

# Authenticate to Azure
Connect-AzAccount
#Write-Host "Request database access token for managed identity"
#$MI_Token = (Get-AzAccessToken -ResourceUrl https://database.windows.net ).Token

# Get the day in Month Day Year format
$date = Get-Date -Format "MM/dd/yyyy"
# Add tag and value to the resource group
$nameValue = $eventGridEvent.data.claims.name
$tags = @{"Creator"="$nameValue";"DateCreated"="$date"}


write-output "Tags:"
write-output $tags

# Resource Group Information:

$rgURI = $eventGridEvent.data.resourceUri
write-output "rgURI:"
write-output $rgURI

# Update the tag value

Try {
    Update-AzTag -ResourceId $rgURI -Tag $tags -operation Merge -ErrorAction Stop
}
Catch {
    $ErrorMessage = $_.Exception.message
    write-host ('Error assigning tags ' + $ErrorMessage)
    Break
}

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

        If ($email) {
            $lastModifiedBy = $email
        } else {
            $lastModifiedBy = $name
        }

        $tags = @{
            "LastModifiedBy"        = $lastModifiedBy
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



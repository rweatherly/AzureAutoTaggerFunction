# Parameter Name must match bindings
param($eventGridEvent, $TriggerMetadata)

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

<#
.SYNOPSIS
Datto RMM script to check for the Sophos Customer Identifier on an endpoint and match it to a provided CSV file of customer IDs and names.

Written by Lee Mackie - 5G Networks

.NOTES
Type: Script

.HISTORY
- Version 1.0 - Initial script creation, checks for customer token and installation status.
#>

# Read the customer identifier from the registry/file
$customerIdPath = "C:\ProgramData\Sophos\Management Communications System\Endpoint\config\config.xml"
# Get CSV file path from user or parameter
$csvPath = "$PWD\customer_data.csv"

# Check if the file exists
if (-not (Test-Path $customerIdPath)) {
    Write-Host "!! ERROR: Customer Identifier file not found at $customerIdPath. Please verify the file path and try again."
    Exit 1
}

if (-not (Test-Path $csvPath)) {
    Write-Host "!! ERROR: CSV file not found at $csvPath. Please verify the file path and try again."
    Exit 1
}

[xml]$sophosConfig = Get-Content $customerIdPath

Write-Host "-- Retrieved Customer Identifier: $($sophosConfig.Configuration.McsClient.customerId)"
Write-Host "-- Retrieved Tenant Identifier: $($sophosConfig.Configuration.McsClient.tenantId)"

# Import CSV
$csvData = Import-Csv -Path $csvPath

# Search for matching customerId
$match = $csvData | Where-Object { $_.customerId -eq $sophosConfig.Configuration.McsClient.customerId -or $_.customerId -eq $sophosConfig.Configuration.McsClient.tenantId }

if (!$match) {
    Write-Host "!! ERROR: No matching customer ID found, as this data is used to match the Sophos Central tenancy you will need to either maunally discover the correct customer, or utilise the following guide to safely uninstall the Sophos endpoint agent."
    Write-Host "!! https://support.sophos.com/support/s/article/KBA-000004158?language=en_US"
    Exit 1
}

Write-Host "-- SUCCESS: Match found! Customer Name: $($match.customerName)"
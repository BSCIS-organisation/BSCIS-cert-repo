param(
    [string]$CsvPath,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

# Default: CSV and terraform.tfvars are next to this script
if ([string]::IsNullOrWhiteSpace($CsvPath)) {
    $CsvPath = Join-Path $PSScriptRoot "terraform_resources.csv"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot "terraform.tfvars"
}

Write-Host "============================================"
Write-Host "CSV Path    : $CsvPath"
Write-Host "Output Path : $OutputPath"
Write-Host "============================================"

# Check CSV
if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

# Read CSV
$rows = @(Import-Csv -LiteralPath $CsvPath)

if ($rows.Count -eq 0) {
    throw "CSV file is empty: $CsvPath"
}

Write-Host "CSV rows found: $($rows.Count)"

function Hcl-String {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return '""'
    }

    $escaped = $Value.Replace('\', '\\').Replace('"', '\"')
    return '"' + $escaped + '"'
}

function Hcl-List {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return '[]'
    }

    $items = $Value -split '[,;]' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" }

    return '[ ' + (($items | ForEach-Object { Hcl-String $_ }) -join ', ') + ' ]'
}

function Hcl-Map {
    param(
        [string]$Title,
        [array]$Items,
        [string[]]$Properties
    )

    $lines = @()

    $lines += "$Title = {"

    foreach ($item in $Items) {

        if ([string]::IsNullOrWhiteSpace($item.key)) {
            throw "Missing key for resource type '$($item.resource_type)'."
        }

        $lines += "  $($item.key) = {"

        foreach ($property in $Properties) {

            $value = [string]$item.$property

            if ($property -eq "address_space" -or
                $property -eq "address_prefixes") {

                $lines += "    $property = $(Hcl-List $value)"
            }
            else {
                $lines += "    $property = $(Hcl-String $value)"
            }
        }

        $lines += "  }"
        $lines += ""
    }

    if ($lines[-1] -eq "") {
        $lines = $lines[0..($lines.Count - 2)]
    }

    $lines += "}"

    return $lines
}

# ============================================================
# Filter resources
# ============================================================

$rgRows = @(
    $rows | Where-Object {
        $_.resource_type -eq "resource_group"
    }
)

$stgRows = @(
    $rows | Where-Object {
        $_.resource_type -eq "storage_account"
    }
)

$vnetRows = @(
    $rows | Where-Object {
        $_.resource_type -eq "vnet"
    }
)

$subnetRows = @(
    $rows | Where-Object {
        $_.resource_type -eq "subnet"
    }
)

Write-Host "Resource Groups   : $($rgRows.Count)"
Write-Host "Storage Accounts  : $($stgRows.Count)"
Write-Host "VNets             : $($vnetRows.Count)"
Write-Host "Subnets           : $($subnetRows.Count)"

# ============================================================
# Validate resource types
# ============================================================

$validTypes = @(
    "resource_group",
    "storage_account",
    "vnet",
    "subnet"
)

$unsupported = @(
    $rows | Where-Object {
        $_.resource_type -notin $validTypes
    }
)

if ($unsupported.Count -gt 0) {

    $types = (
        $unsupported.resource_type |
        Sort-Object -Unique
    ) -join ", "

    throw "Unsupported resource_type found: $types"
}

# ============================================================
# Generate terraform.tfvars
# ============================================================

$output = @()

# ---------------- RESOURCE GROUPS ----------------

if ($rgRows.Count -gt 0) {

    $output += Hcl-Map `
        -Title "dev-rg" `
        -Items $rgRows `
        -Properties @(
            "name",
            "location"
        )
}

$output += ""
$output += "#######################################################################################################################################"
$output += ""

# ---------------- STORAGE ACCOUNTS ----------------

if ($stgRows.Count -gt 0) {

    $output += Hcl-Map `
        -Title "dev-stg" `
        -Items $stgRows `
        -Properties @(
            "name",
            "location",
            "resource_group_name",
            "account_tier",
            "account_replication_type"
        )
}

$output += ""
$output += "#######################################################################################################################################"
$output += ""

# ---------------- VNETS ----------------

if ($vnetRows.Count -gt 0) {

    $output += Hcl-Map `
        -Title "dev-vnet" `
        -Items $vnetRows `
        -Properties @(
            "name",
            "location",
            "resource_group_name",
            "address_space"
        )
}

$output += ""
$output += "#######################################################################################################################################"
$output += ""

# ---------------- SUBNETS ----------------

if ($subnetRows.Count -gt 0) {

    $output += Hcl-Map `
        -Title "dev-subnet" `
        -Items $subnetRows `
        -Properties @(
            "name",
            "resource_group_name",
            "virtual_network_name",
            "address_prefixes"
        )
}

# ============================================================
# Write terraform.tfvars
# ============================================================

$outputDirectory = Split-Path -Parent $OutputPath

if (-not (Test-Path -LiteralPath $outputDirectory)) {

    New-Item `
        -ItemType Directory `
        -Path $outputDirectory `
        -Force |
        Out-Null
}

Set-Content `
    -LiteralPath $OutputPath `
    -Value $output `
    -Encoding UTF8

# ============================================================
# Verify
# ============================================================

if (-not (Test-Path -LiteralPath $OutputPath)) {

    throw "terraform.tfvars was NOT created: $OutputPath"
}

Write-Host ""
Write-Host "============================================================"
Write-Host "terraform.tfvars generated successfully!"
Write-Host "============================================================"
Write-Host "File: $OutputPath"
Write-Host "============================================================"
Write-Host ""

Get-Content -LiteralPath $OutputPath
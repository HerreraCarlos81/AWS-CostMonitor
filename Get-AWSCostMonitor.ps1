# Created by Carlos Herrera
# www.codedneurons.com

# Get the current and previous month names for the report titles
$currentMonthName = (Get-Date).ToString("MMMM yyyy")
$currentMonthName = $currentMonthName.Substring(0,1).ToUpper() + $currentMonthName.Substring(1)
$previousMonthName = (Get-Date).AddMonths(-1).ToString("MMMM yyyy")
$previousMonthName = $previousMonthName.Substring(0,1).ToUpper() + $previousMonthName.Substring(1)

# Set the correct output encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Retrieve all AWS profiles from the credentials file
$credentialsPath = "$env:USERPROFILE\.aws\credentials"
$profiles = Get-Content $credentialsPath | Where-Object { $_ -match '^\[.*\]$' } | ForEach-Object { $_ -replace '\[|\]', '' }

# Filter profiles to include only those containing "cost-monitor" in the name (case-insensitive)
$costMonitorProfiles = $profiles | Where-Object { $_ -match "cost-monitor" }

# Initialize an array to store the report data
$report = @()

# Calculate the current month's start and end dates
$currentStartDate = (Get-Date -Day 1).ToString("yyyy-MM-01")
$currentEndDate = (Get-Date -Day 1).AddMonths(1).ToString("yyyy-MM-01")

# Calculate the previous month's start and end dates
$previousStartDate = (Get-Date -Day 1).AddMonths(-1).ToString("yyyy-MM-01")
$previousEndDate = (Get-Date -Day 1).ToString("yyyy-MM-01")

# Function to get cost for a given period
function Get-AWSCost {
    param (
        [string]$profile,
        [string]$startDate,
        [string]$endDate
    )
    try {
        $env:AWS_PROFILE = $profile
        $costJson = aws ce get-cost-and-usage `
            --time-period Start=$startDate,End=$endDate `
            --granularity MONTHLY `
            --metrics "UnblendedCost" `
            --output json
        $costData = $costJson | ConvertFrom-Json
        if ($costData.ResultsByTime -and $costData.ResultsByTime[0].Total.UnblendedCost) {
            return [math]::Round($costData.ResultsByTime[0].Total.UnblendedCost.Amount, 2)
        } else {
            return 0
        }
    } catch {
        Write-Host "Error retrieving cost for profile '$profile': $_"
        return 0
    }
}

# Loop through each filtered profile to gather billing information
foreach ($profile in $costMonitorProfiles) {
    try {
        # Set the AWS profile for the CLI commands
        $env:AWS_PROFILE = $profile

        # Get the account ID
        $accountId = aws sts get-caller-identity --query "Account" --output text

        # Get the account alias (if available)
        $alias = $null
        try {
            $alias = aws iam list-account-aliases --query "AccountAliases[0]" --output text
        } catch {
            # No action needed, alias will remain null if not available
        }

        # Set account name based on alias, fall back to account ID if no alias
        if ($alias -eq "None" -or $null -eq $alias) {
            $accountName = $accountId
        } else {
            $accountName = $alias
        }

        # Retrieve costs for previous and current months
        $previousCost = Get-AWSCost -profile $profile -startDate $previousStartDate -endDate $previousEndDate
        $currentCost = Get-AWSCost -profile $profile -startDate $currentStartDate -endDate $currentEndDate

        # Calculate variation with enhanced zero handling
		if ($previousCost -eq 0 -and $currentCost -eq 0) {
			$variation = 0  # Both costs are zero, no change
		} elseif ($previousCost -eq 0 -and $currentCost -ne 0) {
			$variation = 100  # Previous cost is zero, current cost is non-zero, treat as a significant increase
		} elseif ($previousCost -ne 0 -and $currentCost -eq 0) {
			$variation = -100  # Previous cost is non-zero, current cost is zero, treat as a full decrease
		} else {
			$variation = [math]::Round((($currentCost - $previousCost) / $previousCost) * 100, 2)  # Standard percentage change
		}

        # Add the account details to the report
        $reportItem = [PSCustomObject]@{
            Profile       = $profile
            Account       = $accountName
            PreviousCost  = $previousCost
            CurrentCost   = $currentCost
            Variation     = $variation
        }
        $report += $reportItem
    } catch {
        Write-Host "Error processing profile '$profile': $_"
    }
}

# Calculate total costs
$previousTotalCost = [math]::Round(($report | Measure-Object -Property PreviousCost -Sum).Sum, 2)
$currentTotalCost = [math]::Round(($report | Measure-Object -Property CurrentCost -Sum).Sum, 2)

# Display the report for previous month
Write-Host "`nAWS Billing Report"
Write-Host "`n$previousMonthName (Profiles containing 'cost-monitor')"
Write-Host "Total Cost: " -NoNewline
Write-Host "$previousTotalCost USD" -ForegroundColor Blue
$report | Select-Object Profile, Account, @{Name='Cost';Expression={'{0:F2} USD' -f $_.PreviousCost}} | Format-Table -AutoSize

# Display the report for current month with variation
Write-Host "$currentMonthName (Profiles containing 'cost-monitor')"
Write-Host "Total Cost: " -NoNewline
Write-Host "$currentTotalCost USD" -ForegroundColor Blue

Write-Host "Profile                            Account           Cost            Variation ($([char]0x0394))"
Write-Host "-------                            -------           ----            -------------"
$report | ForEach-Object {
    $variationColor = if ($_.Variation -gt 0) { 'Red' } elseif ($_.Variation -lt 0) { 'Green' } else { 'Yellow' }
    Write-Host ('{0,-34} {1,-17} {2,-15}' -f $_.Profile, $_.Account, ('{0:F2} USD' -f $_.CurrentCost)) -NoNewline
    Write-Host ('{0:F2}%' -f $_.Variation) -ForegroundColor $variationColor -NoNewline
    Write-Host ('')
}

Write-Host "`nTo view the billing dashboard, run: aws sso login --profile your_profile_name and then visit the AWS console."

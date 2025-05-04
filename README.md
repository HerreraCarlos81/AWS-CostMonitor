# AWS Cost Monitor

A PowerShell script to generate billing reports for AWS accounts, displaying costs for the previous and current months, including a variation percentage with color-coded output. Developed by Carlos Herrera ([www.codedneurons.com](https://www.codedneurons.com)).

## Overview

The `Get-AWSCostMonitor.ps1` script retrieves billing data for AWS profiles containing "cost-monitor" in their names. It generates two reports:
- **Previous Month:** Shows costs for the previous month with total cost across all accounts.
- **Current Month:** Shows costs for the current month, total cost, and a variation percentage (Δ) compared to the previous month, color-coded to indicate increases (red), decreases (green), or no change (yellow).

The script uses the AWS CLI to fetch cost data and ensures proper display of special characters (e.g., Δ) by setting UTF-8 encoding.

## Prerequisites

- **PowerShell 5.1 or later** (included with Windows 10/11 or downloadable for other systems).
- **AWS CLI v2** installed and configured with credentials in `~/.aws/credentials`.
- AWS profiles containing "cost-monitor" in their names, with permissions for:
  - `ce:GetCostAndUsage`
  - `sts:GetCallerIdentity`
  - `iam:ListAccountAliases`
- UTF-8 compatible terminal (e.g., Windows Terminal, PowerShell 7, or VS Code terminal).

## Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/HerreraCarlos81/AWS-CostMonitor.git
   cd AWS-CostMonitor
   ```

2. **Configure AWS CLI:**
   - Ensure AWS credentials are set up in `~/.aws/credentials` with profiles named to include "cost-monitor" (e.g., `[cost-monitor-prod]`).
   - Verify AWS CLI installation:
     ```bash
     aws --version
     ```
   - Configure profiles if needed:
     ```bash
     aws configure --profile cost-monitor-profile-name
     ```

3. **Save the Script:**
   - Ensure `Get-AWSCostMonitor.ps1` is in the repository directory.
   - Save the file with UTF-8 encoding to correctly display the delta symbol (Δ). In VS Code:
     - File > Save with Encoding > UTF-8.

## Usage

1. **Navigate to the Project Directory:**
   ```powershell
   cd C:\path\to\AWS-CostMonitor
   ```

2. **Run the Script:**
   ```powershell
   .\Get-AWSCostMonitor.ps1
   ```

3. **View the Output:**
   - The script displays:
     - Previous month’s report with profile, account, and cost.
     - Current month’s report with profile, account, cost, and variation percentage (Δ).
     - Total costs for each month in blue.
     - Instructions to access the AWS billing dashboard.

## Output Example

```
AWS Billing Report

April 2025 (Profiles containing 'cost-monitor')
Total Cost: 1500.75 USD
Profile             Account           Cost
-------             -------           ----
cost-monitor-prod   prod-account      1000.50 USD
cost-monitor-dev    dev-account       500.25 USD

May 2025 (Profiles containing 'cost-monitor')
Total Cost: 1600.00 USD
Profile                            Account           Cost            Variation (Δ)
-------                            -------           ----            -------------
cost-monitor-prod                  prod-account      1050.00 USD     4.94%  (red)
cost-monitor-dev                   dev-account       550.00 USD      9.95%  (red)

To view the billing dashboard, run: aws sso login --profile your_profile_name and then visit the AWS console.
```

## Features

- **Dual Reports:** Displays costs for the previous and current months.
- **Variation Column:** Shows percentage change (Δ) with color coding:
  - Red: Cost increase (> 0%).
  - Green: Cost decrease (< 0%).
  - Yellow: No change (0%).
- **Total Costs:** Summarizes costs across all accounts, highlighted in blue.
- **UTF-8 Support:** Ensures proper rendering of special characters (e.g., Δ).
- **Error Handling:** Gracefully handles missing aliases or cost data errors.

## Contributing

Contributions are welcome! To contribute:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Commit changes (`git commit -m "Add your feature"`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Credits

Developed by Carlos Herrera ([www.codedneurons.com](https://www.codedneurons.com)). For questions or support, open an issue on GitHub or contact via the website.
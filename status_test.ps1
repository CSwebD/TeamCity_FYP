# This script checks if the performance tests succeeded by reading the latest row from the CSV file.
# Adjust the CSV file path as needed.

$csvPath = "C:\buildAgentFull\artifacts\performance_results.csv"

if (!(Test-Path $csvPath)) {
    Write-Output "CSV file not found. Exiting with error."
    exit 1
}

# Import CSV data (assuming the CSV has a header)
$data = Import-Csv -Path $csvPath

if ($data.Count -eq 0) {
    Write-Output "No data found in CSV. Exiting with error."
    exit 1
}

# Get the last row (latest performance test result)
$lastRow = $data[-1]

# Check if the "Load Time (ms)" field is "N/A" (which indicates failure)
if ($lastRow."Load Time (ms)" -eq "N/A") {
    Write-Output "Performance test failed: Load Time is N/A."
    exit 1
} else {
    Write-Output "Performance test succeeded: Load Time is valid."
    exit 0
}
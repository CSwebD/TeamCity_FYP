# Example: Generate a Line Chart for "Load Time (ms)" from a CSV using PowerShell and .NET

# Load the required .NET assembly for charting
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# Define paths
$csvPath = "C:\buildAgentFull\artifacts\performance_results_overall.csv"
$outputImage = "C:\buildAgentFull\artifacts\loadtime_chart.png"

# Import the CSV data
$data = Import-Csv -Path $csvPath

# Create a new chart object
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Width = 800
$chart.Height = 600

# Create a chart area and add it to the chart
$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea "MainArea"
$chart.ChartAreas.Add($chartArea)

# Create a series for Load Time and set its chart type
$series = New-Object System.Windows.Forms.DataVisualization.Charting.Series "Load Time (ms)"
$series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
$chart.Series.Add($series)

# Loop through CSV data and add points to the series
foreach ($row in $data) {
    # Convert the timestamp to a datetime object
    $timestamp = [datetime]$row.Timestamp
    # Try to parse the load time, if "N/A" skip the row
    if ($row.'Load Time (ms)' -match '^\d+(\.\d+)?$') {
        $loadTime = [double]$row.'Load Time (ms)'
        # Add the data point. XValue is the OLE Automation date of the timestamp.
        $point = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint
        $point.XValue = $timestamp.ToOADate()
        $point.YValues = @($loadTime)
        $series.Points.Add($point)
    }
}

# Format X-Axis to display dates/times
$chartArea.AxisX.LabelStyle.Format = "HH:mm:ss"

# Save the chart as a PNG image
$chart.SaveImage($outputImage, [System.Windows.Forms.DataVisualization.Charting.ChartImageFormat]::Png)

Write-Output "Chart generated and saved to $outputImage"

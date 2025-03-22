Write-Output "Checking webpage functionality..."

# URL to test
$url = "http://127.0.0.1:5500/test/index.html"

# Make an HTTP request to your deployed webpage
try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Output "Webpage responded successfully with status code: $($response.StatusCode)."
        exit 0
    } else {
        Write-Output "Webpage returned unexpected status code: $($response.StatusCode)."
        exit 1
    }
} catch {
    Write-Output "ERROR: Webpage not reachable or functional!"
    exit 1
}
Write-Output "Tests failed. Starting rollback..."

$testPath = "C:\Deployments\test"
$backupPath = "C:\Deployments\backup"

# Safety check (backup not empty)
if ((Get-ChildItem $backupPath).Count -eq 0) {
    Write-Output "Rollback aborted. Backup is empty!"
    exit 1
}

# Rollback backup → test
robocopy $backupPath $testPath /MIR

Write-Output "Rollback completed successfully from backup."
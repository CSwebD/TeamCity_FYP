Write-Output "Test successful. Updating BACKUP folder and pushing ALL files to GitHub..."

# Paths clearly defined
$testPath = "C:\Deployments\test"
$backupPath = "C:\Deployments\backup"
$gitRepoURL = "https://github.com/CSwebD/TeamCity_FYP.git"

$gitUsername = "YourGitHubUsername"
$gitEmail = "your-email@example.com"
$gitToken = "%github_token%"

# Verify backup exists clearly
if (!(Test-Path $backupPath)) {
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
}

# Clearly copy from TEST → BACKUP
robocopy $testPath $backupPath /MIR

# Initialize Git repo (first time only)
if (!(Test-Path "$backupPath\.git")) {
    git init $backupPath
    cd $backupPath
    git remote add origin $gitRepoURL
    git branch -M main
} else {
    cd $backupPath
}

# Clearly add timestamp (to track updates)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Set-Content -Path "$backupPath\last_deployment.txt" -Value "Last successful deployment: $timestamp"

# Commit and push clearly
git config user.name $gitUsername
git config user.email $gitEmail
git add -A
git commit -m "Automated deployment update at $timestamp"
git push -u https://%github_token%@github.com/CSwebD/TeamCity_FYP.git main --force

Write-Output "Backup completed. All changes pushed clearly to GitHub."
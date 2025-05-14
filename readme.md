# CI/CD Pipeline Automation with TeamCity & GitHub

A fully automated CI/CD solution that builds, tests, and deploys web projects using TeamCity, GitHub, PowerShell/Python scripts, and Netlify. Designed to replace manual FTP-based workflows with a robust, repeatable pipeline featuring automatic rollbacks, performance metrics logging, and clear feedback loops.

## 🚀 Features
- Automatic Builds & Deploys

  - Commits to GitHub trigger TeamCity builds

  - Artifacts published to a shared folder and Netlify

- Automated Testing

  - Functional checks via PowerShell (check_webpage_functionality.ps1)

  - Performance audits (Lighthouse + Puppeteer)

  - Generates CSV logs for metrics (network, interaction, load, stability, visual)

- Metrics & Monitoring

  - CSV results stored as TeamCity artifacts

  - generate_charts.py converts CSV → charts for trend analysis

  - Easy review of Time to First Byte (TTFB), Total Load Time, CLS, LCP, etc.

- Reliable Rollbacks

  - Automatic backups of the current live site

  - rollback_from_backup.ps1 restores last-known-good version

- Flexible Configuration

  - Supports parallel/sequential testing (macOS, Ubuntu, Oracle Linux)

  - Configurable via .env and config.toml

  - Retry logic for flaky tests

## 📁 Repository Structure

├── docs/
│   └── pipeline_diagram.png     # Pipeline flowchart (Figure 18 & 19)
├── test_website/                # Sample sites for functional checks
│   ├── site_A.html
│   └── site_B.html
├── scripts/
│   ├── check_webpage_functionality.ps1
│   ├── run_network_metrics.ps1
│   ├── run_interaction_metrics.ps1
│   ├── run_overall_load_metrics.ps1
│   ├── run_stability_metrics.ps1
│   ├── run_visual_metrics.ps1
│   └── run_automated_performance_tests.ps1
├── backup_&_push_to_github.ps1  # Push successful builds
├── rollback_from_backup.ps1     # Restore on failure
├── generate_charts.py           # CSV → chart images
├── number_of_users.json         # Load-test configuration
├── .gitlab-ci.yml               # GitLab CI parent/child pipeline
├── config.toml                  # GitLab Runner settings
└── README.md
## 📦 Getting Started
1. Clone the repo via bash

```bash
git clone https://github.com/YourUsername/CI-CD-TeamCity-GitHub.git
cd CI-CD-TeamCity-GitHub
```

2. Configure Runners

- Install GitLab Runner on your build server (shell & Docker executors).
- Update config.toml with concurrent = 225 and appropriate tags.

Environment Variables
Create a .env file:

ini
Copy
Edit
RUNNERTYPE=DOCKER       # or ALL for macOS + Docker
IMAGETYPE=ALL           # ORACLE_LINUX, UBUNTU
RETRY=TRUE              # retry failed tests
Trigger the Pipeline
Push any change to main (or your selected branch) — the CI/CD pipeline will:

Build Docker images

Deploy child pipelines for each OS

Run functional & performance tests

Publish CSV & chart artifacts

Deploy to Netlify

Notify on success/failure

## 🔧 Configuration
TeamCity

Shared folder triggers builds

Build steps: checkout → tests → backup → deploy

Artifacts stored in C:\buildAgentFull\artifacts

Netlify

Continuous deployment from GitHub

Build & deploy settings under “Build & deploy”

Scripts

Each run_*_metrics.ps1 loads number_of_users.json → runs Lighthouse/Puppeteer → logs CSV

generate_charts.py turns CSV into PNG charts

## 📈 Metrics & Charts
All test data is logged as CSV in the artifacts directory, then converted to charts:

Metric Category	CSV File	Chart Example
Interaction	performance_results_interaction.csv	
Network	performance_results_network.csv	
Overall Load	performance_results_overall.csv	
Stability (CLS)	performance_results_stability.csv	
Visual (LCP/Speed Index)	performance_results_visual.csv	

## 🤝 Contributing
Fork the repo

Create a feature branch (git checkout -b feature/YourFeature)

Commit your changes (git commit -m "Add awesome feature")

Push to the branch (git push origin feature/YourFeature)

Open a Pull Request

## 📜 License
This project is licensed under the MIT License. See the LICENSE[/license] file for details.

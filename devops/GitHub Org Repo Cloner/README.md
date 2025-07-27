## 🧰 GitHub Org Repo Cloner

This Bash script clones all repositories from a given GitHub organization into a local directory. It supports pagination and can use a GitHub personal access token if the repositories are private.

### 🚀 Features
•	Clones all repositories from a GitHub organization using the GitHub API
•	Supports SSH-based cloning with a custom alias (github-alias-account)
•	Skips already cloned repositories
•	Works with both public and private repositories

### 🛠 Requirements
•	bash
•	curl
•	jq
•	git
•	An SSH key with access to the organization’s repositories
•	(Optional) A GitHub Personal Access Token with repo permissions if the repositories are private

### ⚙️ Configuration

    Your GitHub organization name
    ORG="your-org-name"
    
    Your GitHub personal access token (leave blank for public repos)
    GITHUB_TOKEN="ghp_...your_token_here..."
    
    Local directory where the repos will be cloned
    DEST_DIR="$HOME/Documents/github/"

Also make sure your SSH config file (~/.ssh/config) includes an alias like:

    Host github-alias-account
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519
        IdentitiesOnly yes

> ⚠️ Note: The script replaces github.com with github-alias-account to allow using custom SSH keys for multiple GitHub accounts.

### 📦 Usage

Make the script executable and run it:

    chmod +x clone-org-repos.sh
    ./clone-org-repos.sh

It will:

1.	Fetch the list of repositories using the GitHub API
2.	Clone them via SSH into the specified directory
3.	Skip any repository that already exists
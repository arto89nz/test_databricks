#!/bin/bash
#######################################################################################
#Script Name    : init_new_git_repo.sh
#Description    : initializes a new git repo and pushes it to GitHub
#Author         : Arianna Taormina
#Email          : ariannataormina89@gmail.com
#License        : None	
#######################################################################################

# run with following command to be able to activate the env
# source init_git_repo.sh

# Function to validate repo name
function validate_repo_name {
    if [[ "$1" =~ ^[-a-zA-Z0-9]+$ ]]; then return 0; else return 1; fi
}

GITHUB_USERNAME="$GITHUB_USERNAME"
GITHUB_TOKEN="$GITHUB_TOKEN"

# Suggest the current working directory
CURRENT_DIR=$(pwd)
echo
echo
echo "==========================================================================================="
read -p "Current directory is '$CURRENT_DIR'. Do you want to use this directory? (y/n): " confirm

if [[ $confirm == [nN] || $confirm == [nN][oO] ]]; then
    read -p "Enter the local directory path: " LOCAL_DIR
else
    LOCAL_DIR=$CURRENT_DIR
fi

# Create repo name from the last part of the directory
NEW_REPO_NAME=$(basename "$LOCAL_DIR")
read -p "We suggest the repo name as '$NEW_REPO_NAME'. Is this correct? (y/n): " confirm

if [[ $confirm == [nN] || $confirm == [nN][oO] ]]; then
    while true; do
        read -p "Enter a new repo name: " NEW_REPO_NAME
        if validate_repo_name $NEW_REPO_NAME; then
            break
        else
            echo "Invalid name. Only alphanumeric characters and hyphens are allowed. No spaces nor symbols."
        fi
    done
fi


read -p "Enter the Python version for the Conda environment (ex: 3.9, or none ): " PYTHON_VERSION

# Recurrent commit setup
read -p "Do you want to set up recurrent commits for this repository? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    # Copy and edit the commit script template
    cp "/Users/ariannataormina/Documents/GitHub/test_autorepo/commit_git_mod_template.sh" "${LOCAL_DIR}/commit_git_mod.sh"
    # Modify the commit script
    sed -i "" "s#<localfolder>#${LOCAL_DIR}#g" ${LOCAL_DIR}/commit_git_mod.sh
    sed -i "" "s#<gitrepo>#${NEW_REPO_NAME}#g" ${LOCAL_DIR}/commit_git_mod.sh
    RECURRENT_COMMIT_STATUS="Recurrent commit setup completed"
else
    RECURRENT_COMMIT_STATUS="No recurrent commit setup"
fi

echo 
echo "==========================================================================================="

# Initialize a new git repo in the local directory
cd "$LOCAL_DIR" || exit 1
git init

# Create project structure
mkdir -p src tests/unit tests/integration notebooks others
touch src/.gitkeep
touch tests/unit/.gitkeep
touch tests/integration/.gitkeep
touch notebooks/.gitkeep
touch others/.gitkeep
touch src/main.py
touch requirements.txt

# Write initial content to main.py
echo "def main():" >> src/main.py
echo "    pass" >> src/main.py
echo "if __name__ == '__main__':" >> src/main.py
echo "    main()" >> src/main.py

# Create README.md file with project structure description
echo "# $NEW_REPO_NAME" > README.md
echo "### Python version: $PYTHON_VERSION" >> README.md
echo "" >> README.md
echo "This is a Python project with the following structure:" >> README.md
echo "" >> README.md
echo "- **src**: Source code directory" >> README.md
echo "- **src/main.py**: Main Python script" >> README.md
echo "- **tests**: Tests directory" >> README.md
echo "  - **unit**: Unit tests directory" >> README.md
echo "  - **integration**: Integration tests directory" >> README.md
echo "- **notebooks**: Jupyter notebooks directory" >> README.md
echo "- **requirements.txt**: List of Python dependencies" >> README.md
echo "" >> README.md
echo "" >> README.md
echo "```
├── src
│   └── main.py
├── tests
│   ├── unit
│   └── integration
├── notebooks
└── requirements.txt
```" >> README.md

# Add all the new files to git
git add src/main.py tests README.md requirements.txt

# Create .gitignore file with Python project ignores
echo "__pycache__/" >> .gitignore
echo "*.py[cod]" >> .gitignore
echo "*.env" >> .gitignore
echo "*.venv" >> .gitignore
echo "*.egg-info/" >> .gitignore
echo "*.egg" >> .gitignore
echo "*.log" >> .gitignore
echo "*.sql" >> .gitignore
echo "*.sqlite" >> .gitignore

# Add .gitignore to git
git add .gitignore

git add .
git commit -m "Initial project structure"

# Create new GitHub repo using the GitHub API
curl -u "$GITHUB_USERNAME:$GITHUB_TOKEN" https://api.github.com/user/repos -d "{\"name\":\"$NEW_REPO_NAME\",\"private\": true}"

# Check if remote repo exists
if git ls-remote --exit-code "git@github.com:$GITHUB_USERNAME/$NEW_REPO_NAME.git" ; then
    REPO_STATUS="Repo already exists"
    echo "Repo already exists, continue..."
else
    REPO_STATUS="New repo created"
fi

# Push local repo to new GitHub repo
git remote add origin "git@github.com:$GITHUB_USERNAME/$NEW_REPO_NAME.git"
git branch -M main
git push -u origin main

if [[ $PYTHON_VERSION == "none" ]]; then
    CONDA_ENV_NAME="none"
    CONDA_STATUS="No Conda environment associated"
else
    # Create a new Conda environment with the specified Python version
    CONDA_ENV_NAME="${NEW_REPO_NAME// /_}_python_${PYTHON_VERSION//./_}"
    if conda env list | grep -q $CONDA_ENV_NAME; then
        echo "Environment '$CONDA_ENV_NAME' already exists, continue..."
        CONDA_STATUS="Environment '$CONDA_ENV_NAME' already exists"
    else
        conda create -n $CONDA_ENV_NAME python=$PYTHON_VERSION -y
        CONDA_STATUS="New Conda environment created"
    fi

    # Activate the Conda environment
    #source activate $CONDA_ENV_NAME
    source "$(conda info --base)/bin/activate" $CONDA_ENV_NAME
    # Check the activated Conda environment
    echo "Activated Conda environment: $(conda info --envs | grep '*' | awk '{print $1}')"
fi


# Summary message
echo
echo "Summary:"
echo "  - $REPO_STATUS"
echo "  - $CONDA_STATUS"
echo "  - $RECURRENT_COMMIT_STATUS"
echo "New private repo has been pushed to git@github.com:$GITHUB_USERNAME/$NEW_REPO_NAME.git"

#!/bin/bash 
#######################################################################################
#Script Name    : commit_git_mod.sh
#Description    : regularly commits changes from given repo 
#Args           : None      
#Author         : Arianna Taormina
#Email          : ariannataormina89@gmail.com
#License        : None	
#######################################################################################

MESSAGE="Update_$(date)"
DESTINATION_BRANCH="main"
LOCAL_REPO="C:\Users\ARTO\Documents\GitHUB\test_databricks"
GIT_REPO="git@github.com:arto89nz/test_databricks.git"
SEPARATOR="#######################################"

cd "$LOCAL_REPO" || exit 1

# Update requirements.txt
pip freeze > requirements.txt

# pull changes before committing them
if ! git pull; then
  echo "git pull failed"
  exit 1
fi

echo " "
echo "$SEPARATOR"

# Check for changes
if [ -z "$(git status --porcelain)" ]; then
  echo "No changes to commit"
  exit 0
fi

echo "You're about to push your changes"
echo "from:$LOCAL_REPO"
echo "to:$GIT_REPO"
echo " "

git add .     
if ! git commit -m "$MESSAGE"; then
  echo "git commit failed"
  exit 1
fi

if ! git push -u origin "$DESTINATION_BRANCH"; then
  echo "git push failed"
  exit 1
fi

echo " "
echo "Hope to see you again!"
echo "$MESSAGE"
echo " "
echo "$SEPARATOR"

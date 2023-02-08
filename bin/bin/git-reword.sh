#! /bin/bash

if [ -z "$1" ];
then
    echo "No SHA provided. Usage: \"git reword <SHA>\"";
    exit 1;
fi;
if [ $(git rev-parse $1) == $(git rev-parse HEAD) ];
then
    echo "$1 is the current commit on this branch.  Use \"git commit --amend\" to reword the current commit.";
    exit 1;
fi;
git merge-base --is-ancestor $1 HEAD;
ANCESTRY=$?;
if [ $ANCESTRY -eq 1 ];
then
    echo "SHA is not an ancestor of HEAD.";
    exit 1;
elif [ $ANCESTRY -eq 0 ];
then
    git stash;
    START=$(git rev-parse --abbrev-ref HEAD);
    git branch savepoint;
    git reset --hard $1;
    git commit --amend;
    git rebase -p --onto $START $1 savepoint;
    git checkout $START;
    git merge savepoint;
    git branch -d savepoint;
    git stash pop;
else
    exit 2;
fi

#!/bin/sh -l

# INPUT_TOKEN
# INPUT_REPOSITORY
# INPUT_REF
# INPUT_BASE_REF
# INPUT_HEAD_REF 
# INPUT_TRIGGERING_ACTOR
ROOT_DIR="/"
PULL_NUMBER=$(grep -o '[0-9]*' $INPUT_REF)

git clone "https://$INPUT_TOKEN@github.com/$INPUT_REPOSITORY.git" repo

if [ -d repo ]; then
    cd $ROOT_DIR/repo
    git pull origin $INPUT_BASE_REF
    git pull origin $INPUT_HEAD_REF
    git checkout $INPUT_HEAD_REF
    
    edited_files=`git diff --name-only $INPUT_BASE_REF | grep -i '.tf$' `
    reformated_files="Next files are reformatted\n\n"
    for edited_file in $edited_files; do
        reformated_file=$(terraform fmt $edited_file)
        if [ -z "$reformated_file" ]; then
            reformated_files+="- $reformated_file\n"
        done
    done

    git add .

    # If exist re-formatting .tf file
    if [ -z "$(git status)"]; then

        git config --global user.name $INPUT_TRIGGERING_ACTOR && \
            git config --global user.email $INPUT_TRIGGERING_ACTOR@github.com && \
            git commit --amend --no-edit && \
            git push --force && \
            curl -L \
                -X POST \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $INPUT_TOKEN"\
                -H "X-GitHub-Api-Version: 2022-11-28" \
                https://api.github.com/repos/$INPUT_REPOSITORY/issues/$PULL_NUMBER/comments \
                -d '{"body":"'$reformated_files'"}'

    done

done

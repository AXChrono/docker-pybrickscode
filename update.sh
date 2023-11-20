#!/bin/bash

# Run this script to update this repository and get in sync with the latest Pybricks Code tag.

# Files to update automatically with the new tags.
FILES_TO_UPDATE=(
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.build.yml"
)

# Save the current tags of the docker repository in a variable.
PYBRICKSCODE_TAG_OLD=$(cat Dockerfile | grep -o 'ARG PYBRICKSCODE_TAG=[^ ,]\+' | sed s/"ARG PYBRICKSCODE_TAG="//)
NODEJS_TAG_OLD=$(cat Dockerfile | grep -o 'ARG NODE_TAG=[^ ,]\+' | sed s/"ARG NODE_TAG="//)

# Download the latest version of Pybricks Code in a temporary folder.
git clone https://github.com/pybricks/pybricks-code.git ./.temp/pybricks-code

# Save the current tags of the program repository in a variable.
cd ./.temp/pybricks-code
PYBRICKSCODE_TAG_NEW=$(git tag --sort=creatordate | grep -C1 -Fx $PYBRICKSCODE_TAG_OLD | tail -1)
PYBRICKSCODE_TAG_NEWER=$(git tag --sort=creatordate | grep -A2 -Fx $PYBRICKSCODE_TAG_OLD | tail -1)
PYBRICKSCODE_TAG_LATEST=$(git tag --sort=creatordate | tail -1)
# Only reason the new tag will be empty is when the old tag is not in the git tag list.
# This can also be exploited to start fresh and create every a container for every tag.
if [[ $PYBRICKSCODE_TAG_NEW == '' ]]; then
    PYBRICKSCODE_TAG_NEW=$(git tag --sort=creatordate | head -1)
    PYBRICKSCODE_TAG_NEWER=$(git tag --sort=creatordate | head -2)
fi
git checkout $PYBRICKSCODE_TAG_NEW
NODEJS_TAG_NEW=$(cat .tool-versions | grep -o 'nodejs [^ ,]\+' | sed s/"nodejs "//)
cd ..
cd ..
echo ""

# Remove the temporary files.
rm -rf ./.temp

# Echo the old and new tags to the cosole.
echo "Old Pybricks Code tag: $PYBRICKSCODE_TAG_OLD"
echo "New Pybricks Code tag: $PYBRICKSCODE_TAG_NEW"
echo "Old NodeJS tag:        $NODEJS_TAG_OLD"
echo "New NodeJS tag:        $NODEJS_TAG_NEW"
echo ""

# Check if there is a newer tag that the tag we current update to.
EXTRA_UPDATE_RUN=false
if [[ "$PYBRICKSCODE_TAG_NEW" != "$PYBRICKSCODE_TAG_LATEST" ]]; then
    EXTRA_UPDATE_RUN=true
    echo "$PYBRICKSCODE_TAG_LATEST is the latest version but in this run the repository will be updated to $PYBRICKSCODE_TAG_NEW."
    echo "After this update run the update again to update to $PYBRICKSCODE_TAG_NEWER"
    echo ""
fi

# If no update is needed, exit the script.
if [[ "$PYBRICKSCODE_TAG_OLD" == "$PYBRICKSCODE_TAG_NEW" ]]; then
    echo "Docker tag and program tag are the same. No update needed"

    # Wait for the user to exit the script.
    read -p "Press the [Enter] key to exit..."
    exit 0
fi

# If an update is possible wait for the user to continue.
if [[ $1 != auto_update ]]; then
    echo "Does the above look OK?"
    read -p "Press the [Enter] key to continue..."
fi

# Update the tags in the different files.
for i in "${!FILES_TO_UPDATE[@]}"; do
    sed -i "s/$PYBRICKSCODE_TAG_OLD/$PYBRICKSCODE_TAG_NEW/g" ${FILES_TO_UPDATE[i]}
    sed -i "s/$NODEJS_TAG_OLD/$NODEJS_TAG_NEW/g" ${FILES_TO_UPDATE[i]}
done

# Commit the new update to the git repository and set the new tag.
git add .
git commit -m $PYBRICKSCODE_TAG_NEW
git tag $PYBRICKSCODE_TAG_NEW

# Build the Dockerfile and push to DokcerHub.
# Check if the new tag is a beta tag and set the docker tags acordingly.
if [[ "$PYBRICKSCODE_TAG_NEW" == *"beta"* ]]; then
    docker build --rm -f "Dockerfile" \
        -t axchrono/pybrickscode:$PYBRICKSCODE_TAG_NEW \
        -t axchrono/pybrickscode:latest-beta \
        "."
    docker image push axchrono/pybrickscode:$PYBRICKSCODE_TAG_NEW
    docker image push axchrono/pybrickscode:latest-beta
# Check if the new tag is a release candidate tag and set the docker tags acordingly.
elif [[ "$PYBRICKSCODE_TAG_NEW" == *"rc"* ]]; then
    docker build --rm -f "Dockerfile" \
        -t axchrono/pybrickscode:$PYBRICKSCODE_TAG_NEW \
        -t axchrono/pybrickscode:latest-beta \
        -t axchrono/pybrickscode:latest-rc \
        "."
    docker image push axchrono/pybrickscode:$PYBRICKSCODE_TAG_NEW
    docker image push axchrono/pybrickscode:latest-beta
    docker image push axchrono/pybrickscode:latest-rc
# If the new tag is not a beta or release candidate asume that it is a stable release.
else
    docker build --rm -f "Dockerfile" \
        -t axchrono/pybrickscode:$PYBRICKSCODE_TAG_NEW \
        -t axchrono/pybrickscode:latest-beta \
        -t axchrono/pybrickscode:latest-rc \
        -t axchrono/pybrickscode:latest \
        "."
    docker image push axchrono/pybrickscode:$PYBRICKSCODE_TAG_NEW
    docker image push axchrono/pybrickscode:latest-beta
    docker image push axchrono/pybrickscode:latest-rc
    docker image push axchrono/pybrickscode:latest
fi

# Run if there is still an update left to do.
if [[ "$EXTRA_UPDATE_RUN" == true ]]; then
    echo ""
    if [[ $1 != auto_update ]]; then
        read -p "Press the [Enter] key to do a run for $PYBRICKSCODE_TAG_NEWER..."
    fi
    clear
    ./update.sh $1
    exit 0
fi

# Wait for the user to exit the script.
read -p "Press the [Enter] key to exit..."
exit 0

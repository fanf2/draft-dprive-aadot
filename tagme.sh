#!/bin/sh

set -eu

filename=$(./stamp.sh)
# create dummy tag to ensure tag does not already exist
# before we make any commits
git tag --annotate -m $filename $filename
# first dummy commit to set the timestamp
git add draft.md
git commit --allow-empty -m $filename
# update commit so it contains its own timestamp
filename=$(./stamp.sh)
git add draft.md
git commit --allow-empty --no-edit --amend
# move the tag to the correct commit
git tag --delete $filename
git tag --annotate -m $filename $filename

git --no-pager show HEAD

basename=${filename%-*}
version=${filename##*-}
nextname=$basename-$(printf '%02d' $((version+1)) )
sed -i "s/$filename/$nextname/" draft.md
echo
echo "next version will be $nextname"

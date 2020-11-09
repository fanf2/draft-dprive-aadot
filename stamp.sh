#!/bin/sh

set -eu

date=$(git log --max-count=1 --format=%ad --date=format:%FT%TZ draft.md)

filename=$(sed '
	/^%%%/,/^%%%/!d;
	/value[      ]*=[    ]*"\([^"]*\)"/!d;
	s//\1/;
' draft.md)

sed '/^%%%/,/^%%%/s/\(^date[	 ]*=[	 ]*\).*/\1'$date'/' \
    <draft.md >draft.stamp

if ! diff -u draft.stamp draft.md 1>&2
then mv draft.stamp draft.md
else rm draft.stamp
fi

echo $filename

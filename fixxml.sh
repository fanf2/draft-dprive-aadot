#!/bin/sh

set -eu

# mangle output from mmark to fix cosmetic issues

# RFC 2629 uses a single <t> paragraph per list item, so when you want
# multiple paragraphs in a list item you need to use physical
# linebreaks instead of semantic markup. Paragraph breaks need to
# appear as a blank line, but `mmark` only inserts a single linebreak.

sed '
    s|<vspace />|<vspace blankLines="1"/>|
'

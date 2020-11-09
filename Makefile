MMARK=${GOPATH}/bin/mmark

DRAFT!=./stamp.sh

OUT= ${DRAFT}.html ${DRAFT}.xml ${DRAFT}.txt

all: ${OUT}

${DRAFT}.html: ${DRAFT}.xml
	xml2rfc --html -o ${DRAFT}.html ${DRAFT}.xml

${DRAFT}.xml: draft.md
	${MMARK} -2 draft.md >${DRAFT}.xml

${DRAFT}.txt: ${DRAFT}.xml
	xml2rfc --raw -o ${DRAFT}.txt ${DRAFT}.xml

commit: ${OUT}
	git add ${OUT}
	git commit -m 'Update rendered versions'

clean:
	rm -f ${OUT}

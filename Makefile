MMARK	=	mmark
XML2RFC	=	xml2rfc

DRAFT	!=	./stamp.sh

OUT	=	${DRAFT}.html ${DRAFT}.xml ${DRAFT}.txt

all: ${OUT}

${DRAFT}.xml: draft.md fixxml.sh
	${MMARK} draft.md | ./fixxml.sh >${DRAFT}.xml

${DRAFT}.html: ${DRAFT}.xml
	${XML2RFC} --html -o ${DRAFT}.html ${DRAFT}.xml

${DRAFT}.txt: ${DRAFT}.xml
	${XML2RFC} --text -o ${DRAFT}.txt ${DRAFT}.xml

commit: ${OUT}
	git add ${OUT}
	git commit -m 'Update rendered versions'

clean:
	rm -f ${OUT}

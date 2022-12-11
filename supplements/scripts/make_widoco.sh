#!/bin/bash
set -eu
shopt -s extglob

ROOT=https://schema.coypu.org
all_ontos=(
ontology/events/em-dat.ttl
ontology/events/gta.ttl
ontology/events/rta.ttl
ontology/infrastructure/world-port-index.ttl
ontology/mapping/coy_wikidata.ttl
ontology/meta/template.ttl
ontology/global/coy.ttl
)
STATS_FILE=void.stats.ttl

myid=$$

rpt() {
    java -jar rpt-1.9.2-rc1.jar "$@"
}

# filter out Java warnings
rpt_skip_lines=$(rpt ngs map -d /dev/null 2>/dev/null |wc -l)

rpt() {
    set -o pipefail
    java -jar rpt-1.9.2-rc1.jar "$@" \
	| tail -n +$((rpt_skip_lines+1))
    set +o pipefail
}

T0=tmp.$myid

cleanup() {
    rm -fr "$T0"
}

trap 'cleanup' EXIT

if [[ ! -f "$STATS_FILE" ]]; then
    echo "$STATS_FILE" not found >&2
    exit 1
fi

mkdir -p $T0/widoco_master
echo "<link rel='stylesheet' href='resources/primer.css' media='screen' /><link rel='stylesheet' href='resources/rec.css' media='screen' /><link rel='stylesheet' href='resources/extra.css' media='screen' /><link rel='stylesheet' href='resources/owl.css' media='screen' />
<h1>CoyPu Ontology schemas</h1><dl>" > $T0/widoco_master/index.html

for ont_file in "${all_ontos[@]}"; do
    if [[ ! -f "$ont_file" ]]; then
	echo "$ont_file" not found >&2
	exit 1
    fi
    rpt integrate --out-format=ntriples "$ont_file" '
        construct {
            ?s a owl:Ontology ;
                <urn:x-tmp:filename> "'"$ont_file"'" ;
                owl:versionIRI ?ver ;
        } { ?s a owl:Ontology . optional { ?s owl:versionIRI ?ver } }'
done > $T0/allOntologies.nt

cat >$T0/widoco_master/.htaccess <<T
Options +MultiViews

AddType text/html .html
AddType application/rdf+xml .rdf
AddType text/turtle .ttl
AddType application/n-triples .nt
AddType application/ld+json .jsonld

T

for input in "${all_ontos[@]}"; do
    mybase="$(awk '$2 == "<urn:x-tmp:filename>" && $3 == "\"'"$input"'\"" { gsub("[#/]>",">",$1); gsub("[<>]","",$1); print $1 }' $T0/allOntologies.nt)"
    myver="$(awk '$1 == "<'"$mybase"'>" && $2 == "<http://www.w3.org/2002/07/owl#versionIRI>"{ gsub("[#/]>",">",$3); gsub("[<>]","",$3); print $3 }' $T0/allOntologies.nt)"
    if [[ -z "$myver" ]]; then
	myver=$mybase
    fi
    pathname="$(basename "$mybase")"
    basefname="${mybase/#*:\/\/*([^\/])\/}"
    ontfname="${myver/#*:\/\/*([^\/])\/}"
    ontfname_frag=${ontfname//\//-}
    ontf_up="$(dirname "${ontfname//+([^\/])/..}")"
    echo "#####################################################################" >&2
    echo "... processing $input <$mybase> => $ontfname ..." >&2
    T=$T0/"$pathname"
    mkdir -p $T

    cp $T0/allOntologies.nt $T/
    rpt integrate -o=$T/onlyVoid.nt --out-format=ntriples "$STATS_FILE" supplements/scripts/extractVoidInformation.rq
    rpt integrate -o=$T/parentClass.nt --out-format=ntriples "$input" $T/onlyVoid.nt supplements/scripts/createParentClassStatInfo.rq
    rpt integrate -o=$T/notInUse.nt --out-format=ntriples "$input" $T/onlyVoid.nt $T/parentClass.nt supplements/scripts/createNotInUseStatus.rq
    rpt integrate -o=$T/missing.nt --out-format=ntriples "${all_ontos[@]}" "$STATS_FILE" supplements/scripts/usedButNotInOnto.rq
    ontology_bases=($(awk '{gsub("[#/]>",">",$1)} !seen[$1]++ {gsub("[<>]","",$1); print $1}' $T/allOntologies.nt))
    if [[ "$pathname" == global ]]; then
	for base in "${ontology_bases[@]}"; do
	    if [[ "$base" == "$ROOT/$pathname" ]]; then
		: # skip
	    else
		sed -i -e "\\|^<${base}[/#>]|d" $T/missing.nt
	    fi
	done
    else
	sed -n -i -e "\\|^<${ROOT}/${pathname}[/#>]|p" $T/missing.nt
    fi

    rpt integrate -o=$T/annotated.ttl --out-format=turtle "$input" $T/onlyVoid.nt $T/parentClass.nt $T/notInUse.nt $T/missing.nt 'construct { ?s ?p ?o } { ?s ?p ?o }'

    rpt integrate -o=$T/plain.ttl --out-format=turtle "$input" 'construct { ?s ?p ?o } { ?s ?p ?o }'
    sed -i -e 's|%\(2[89]\)|__x__\1|g' $T/annotated.ttl $T/plain.ttl
    java -jar java-17-widoco-1.4.17-jar-with-dependencies.jar -ontFile $T/plain.ttl -lang en -getOntologyMetadata -rewriteAll -webVowl -licensius -includeAnnotationProperties -noPlaceHolderText -outFolder $T/widoco_out
    java -jar java-17-widoco-1.4.17-jar-with-dependencies.jar -ontFile $T/annotated.ttl -lang en -getOntologyMetadata -rewriteAll -webVowl -licensius -includeAnnotationProperties -noPlaceHolderText -outFolder $T/widoco_out_annot
    if [[ -d $T/widoco_out/doc ]]; then
	mv $T/widoco_out/doc $T/widoco_out_doc
	rm -fr $T/widoco_out
	mv $T/widoco_out_doc $T/widoco_out
	#
	mv $T/widoco_out_annot/doc $T/widoco_out_annot_doc
	rm -fr $T/widoco_out_annot
	mv $T/widoco_out_annot_doc $T/widoco_out_annot
    fi
    sed -i -e 's|__x__|%|g' $T/widoco_out/ontology.* $T/widoco_out/webvowl/data/ontology.json $T/widoco_out/sections/*.html \
	 $T/widoco_out_annot/ontology.* $T/widoco_out_annot/webvowl/data/ontology.json $T/widoco_out_annot/sections/*.html
    sed -i \
	-e "/<script>/a \
\\
  function addHl() {\
    var x = document.evaluate(\"//dl[./dd[text()='CoyPu graph: ---USED BUT NOT IN ONTOLOGY---']]\", document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);\
    for (var i = 0; i < x.snapshotLength; i++) {\
      x.snapshotItem(i).style='background-color:red;border-radius:5px';\
    }\
    var x = document.evaluate(\"//dl[./dd[text()='CoyPu graph: Not currently in use']]\", document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);\
    for (var i = 0; i < x.snapshotLength; i++) {\
      x.snapshotItem(i).style='background-color:yellow;border-radius:5px';\
    }\
  }\
" \
	-e "/\$(\"#toc\")\.html(t);/a \
\\
    addHl();\
" \
	-e 's|"ontology\.|"'"$ontf_up/$ontfname"'.|g' \
	-e 's|"sections/|"'"$ontf_up/$ontfname_frag"'-sections/|g' \
	-e 's|"provenance/|"'"$ontf_up/$ontfname_frag"'-provenance/|g' \
	$T/widoco_out/index-en.html
    #sed -i -e 's|webvowl/index.html|webvowl/index.html#'"$ontfname_frag"'|' $T/widoco_out/sections/overview-en.html
    sed -i -e 's|webvowl/index.html|'"$ontf_up/webvowl/index.html#$ontfname_frag"'|' $T/widoco_out/sections/overview-en.html
    perl -i -p -e 's{\b(href|src)="([^"]+?)"}{
        my ($attr, $link) = ($1, $2);
        $link = "'"$ontf_up"'/$link"
          unless $link =~ m{://} || $link =~ m{^[/#.]};
        qq{$attr="$link"}
      }ge' $T/widoco_out/index-en.html

    mkdir -p $T/widoco_out/"$(dirname "$ontfname")"
    for ont_file in $T/widoco_out/webvowl/data/ontology.json; do
	mv -v "$ont_file" "${ont_file/\/ontology./\/"$ontfname_frag".}"
    done
    for ont_file in $T/widoco_out/ontology.*; do
	mv -v "$ont_file" "${ont_file/\/ontology./\/"$ontfname".}"
    done
    mv -v $T/widoco_out_annot/sections/crossref-*.html $T/widoco_out/sections
    rm -fr $T/widoco_out_annot
    mv -v $T/widoco_out/sections $T/widoco_out/"$ontfname_frag"-sections
    mv -v $T/widoco_out/provenance $T/widoco_out/"$ontfname_frag"-provenance
    mv -v $T/widoco_out/index-en.html $T/widoco_out/"$ontfname".html
    rsync -a $T/widoco_out// $T0/widoco_master//
    echo "<dt><tt>$mybase</tt><dd><a href='$basefname'>$basefname</a>" >> $T0/widoco_master/index.html
    if [[ "$mybase" != "$myver" ]]; then
	echo RedirectMatch temp '"(/'"$basefname"')/?(\.[^/]*|$)"' '"/'"$ontfname"'$2"' >> $T0/widoco_master/.htaccess
    fi
done

echo "</dl><p><small><i>Last update: $(LANG=C TZ=UTC date)</i> <i>Git version: $(LANG=C git rev-parse --short HEAD)</i></small>" >> $T0/widoco_master/index.html

rm -fr widoco_master.old || :
mv widoco_master widoco_master.old 2>/dev/null || :
mv $T0/widoco_master .

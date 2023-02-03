#!/bin/bash
set -eu
shopt -s extglob

ROOT=https://schema.coypu.org
CORE=global
ONTOLOGY_DIR=ontology
STATS_FILE=void.stats.ttl

myid=$$

mapfile -t all_files < <(find "$ONTOLOGY_DIR" -type f | sort -V)

rpt() {
    java -jar rpt-1.9.2-rc1.jar "$@"
}

echo "loading rpt..." >&2

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

mkdir -p "$T0"/widoco_master
echo "<link rel='stylesheet' href='resources/primer.css' media='screen' /><link rel='stylesheet' href='resources/rec.css' media='screen' /><link rel='stylesheet' href='resources/extra.css' media='screen' /><link rel='stylesheet' href='resources/owl.css' media='screen' />
<h1>CoyPu Ontology schemas</h1><dl>" > "$T0"/widoco_master/index.html

for file in "${all_files[@]}"; do
    { {
        rpt integrate --out-format=ntriples "$file" '
            construct {
                ?s a owl:Ontology ;
                    <urn:x-tmp:filename> "'"$file"'" ;
                    owl:versionIRI ?ver ;
            } { ?s a owl:Ontology . optional { ?s owl:versionIRI ?ver } } order by ?ver ?s'
    } 2>&1 >&3 | head >&2; } 3>&1
done > "$T0"/allOntologies.nt

all_ontos=()
for file in "${all_files[@]}"; do
    mybase="$(awk '$2 == "<urn:x-tmp:filename>" && $3 == "\"'"$file"'\"" { gsub("[#/]>",">",$1); gsub("[<>]","",$1); print $1 }' "$T0"/allOntologies.nt)"
    if [[ -n "$mybase" ]]; then
        if [[ "$mybase" == *$'\n'* ]]; then
            echo "ERROR: multiple ontologies defined in $file" >&2
            exit 1
        fi

        pathname="$(basename "$mybase")"
        if [[ "$pathname" == "$CORE" ]]; then
            all_ontos+=("$file")
        else
            all_ontos=("$file" "${all_ontos[@]}")
        fi
        echo "... found ontology file $file => <$mybase> ..." >&2
    fi
done

cat >"$T0"/widoco_master/.htaccess <<T
Options +MultiViews

AddType text/html .html
AddType application/rdf+xml .rdf
AddType text/turtle .ttl
AddType application/n-triples .nt
AddType application/ld+json .jsonld

T

target_paths=()
for input in "${all_ontos[@]}"; do
    # the ontology IRI
    mybase="$(awk '$2 == "<urn:x-tmp:filename>" && $3 == "\"'"$input"'\"" { gsub("[#/]>",">",$1); gsub("[<>]","",$1); print $1 }' "$T0"/allOntologies.nt)"

    # the ontology version IRI
    myver="$(awk '$1 == "<'"$mybase"'>" && $2 == "<http://www.w3.org/2002/07/owl#versionIRI>"{ gsub("[#/]>",">",$3); gsub("[<>]","",$3); print $3 }' "$T0"/allOntologies.nt)"
    if [[ -z "$myver" ]]; then
        myver=$mybase
    fi
    pathname="$(basename "$mybase")"

    basefname="${mybase/#*:\/*(\/)*([^\/])\/}"

    # path and name for the ontology files, without extension
    ontfname="${myver/#*:\/*(\/)*([^\/])\/}"

    # prefix name for the fragment file folders
    ontfname_frag=${ontfname//\//-}

    # relative parent folder expression to find the root (`../../..` ...)
    ontf_up="$(dirname "${ontfname//+([^\/])/..}")"
    T="$T0/$pathname"
    mkdir -p "$T"

    cp "$T0"/allOntologies.nt "$T"/
    target_paths+=("$pathname")

    echo "<dt><tt>$mybase</tt><dd><a href='$basefname'>$basefname</a>" >> "$T0"/widoco_master/index.html
    if [[ "$mybase" != "$myver" ]]; then
        echo RedirectMatch temp '"(/'"$basefname"')/?(\.[^/]*|$)"' '"/'"$ontfname"'$2"' >> "$T0"/widoco_master/.htaccess
    fi
    { {
        echo "#####################################################################" >&2
        echo "... processing $input <$mybase> => $ontfname ..." >&2
        rpt integrate -o="$T"/onlyVoid.nt --out-format=ntriples "$STATS_FILE" supplements/scripts/extractVoidInformation.rq
        rpt integrate -o="$T"/parentClass.nt --out-format=ntriples "$input" "$T"/onlyVoid.nt supplements/scripts/createParentClassStatInfo.rq
        rpt integrate -o="$T"/notInUse.nt --out-format=ntriples "$input" "$T"/onlyVoid.nt "$T"/parentClass.nt supplements/scripts/createNotInUseStatus.rq
        rpt integrate -o="$T"/missing.nt --out-format=ntriples "${all_ontos[@]}" "$STATS_FILE" supplements/scripts/usedButNotInOnto.rq
        ontology_bases=($(awk '{gsub("[#/]>",">",$1)} !seen[$1]++ {gsub("[<>]","",$1); print $1}' "$T"/allOntologies.nt))
        if [[ "$pathname" == "$CORE" ]]; then
            for base in "${ontology_bases[@]}"; do
                if [[ "$base" == "$mybase" ]]; then
                    : # skip
                else
                    sed -i -e "\\|^<${base}[/#>]|d" "$T"/missing.nt
                fi
            done
        else
            sed -n -i -e "\\|^<${mybase}[/#>]|p" "$T"/missing.nt
        fi

        rpt integrate -o="$T"/annotated.ttl --out-format=turtle "$input" "$T"/onlyVoid.nt "$T"/parentClass.nt "$T"/notInUse.nt "$T"/missing.nt 'construct { ?s ?p ?o } { ?s ?p ?o } order by ?s ?p ?o'

        rpt integrate -o="$T"/plain.ttl --out-format=turtle "$input" 'construct { ?s ?p ?o } { ?s ?p ?o } order by ?s ?p ?o'
        sed -i -e 's|%\(2[89]\)|__x__\1|g' "$T"/annotated.ttl "$T"/plain.ttl
        set -o pipefail
        my_widocos=()
        { {
            java -jar java-17-widoco-1.4.17-jar-with-dependencies.jar -ontFile "$T"/plain.ttl -lang en -getOntologyMetadata -rewriteAll -webVowl -licensius -includeAnnotationProperties -noPlaceHolderText -outFolder "$T"/widoco_out
        } 2>&1 >&3 | sed -e "s|^|[plain:E] |" >&2; } 3>&1 | sed -e "s|^|[plain:O] |" &
        my_widocos+=($!)
        { {
            java -jar java-17-widoco-1.4.17-jar-with-dependencies.jar -ontFile "$T"/annotated.ttl -lang en -getOntologyMetadata -rewriteAll -webVowl -licensius -includeAnnotationProperties -noPlaceHolderText -outFolder "$T"/widoco_out_annot
        } 2>&1 >&3 | sed -e "s|^|[annot:E] |" >&2; } 3>&1 | sed -e "s|^|[annot:O] |" &
        my_widocos+=($!)
        wait "${my_widocos[@]}"
        set +o pipefail
        if [[ -d "$T"/widoco_out/doc ]]; then
            mv "$T"/widoco_out/doc "$T"/widoco_out_doc
            rm -fr "$T"/widoco_out
            mv "$T"/widoco_out_doc "$T"/widoco_out
            #
            mv "$T"/widoco_out_annot/doc "$T"/widoco_out_annot_doc
            rm -fr "$T"/widoco_out_annot
            mv "$T"/widoco_out_annot_doc "$T"/widoco_out_annot
        fi
        sed -i -e 's|__x__|%|g' "$T"/widoco_out/ontology.* "$T"/widoco_out/webvowl/data/ontology.json "$T"/widoco_out/sections/*.html \
            "$T"/widoco_out_annot/ontology.* "$T"/widoco_out_annot/webvowl/data/ontology.json "$T"/widoco_out_annot/sections/*.html
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
            "$T"/widoco_out/index-en.html
        #sed -i -e 's|webvowl/index.html|webvowl/index.html#'"$ontfname_frag"'|' "$T"/widoco_out/sections/overview-en.html
        sed -i -e 's|webvowl/index.html|'"$ontf_up/webvowl/index.html#$ontfname_frag"'|' "$T"/widoco_out/sections/overview-en.html
        perl -i -p -e 's{\b(href|src)="([^"]+?)"}{
            my ($attr, $link) = ($1, $2);
            $link = "'"$ontf_up"'/$link"
              unless $link =~ m{://} || $link =~ m{^[/#.]};
            qq{$attr="$link"}
          }ge' "$T"/widoco_out/index-en.html

        mkdir -p "$T"/widoco_out/"$(dirname "$ontfname")"
        for ont_file in "$T"/widoco_out/webvowl/data/ontology.json; do
            mv -v "$ont_file" "${ont_file/\/ontology./\/"$ontfname_frag".}"
        done
        for ont_file in "$T"/widoco_out/ontology.*; do
            mv -v "$ont_file" "${ont_file/\/ontology./\/"$ontfname".}"
        done
        mv -v "$T"/widoco_out_annot/sections/crossref-*.html "$T"/widoco_out/sections
        rm -fr "$T"/widoco_out_annot
        mv -v "$T"/widoco_out/sections "$T"/widoco_out/"$ontfname_frag"-sections
        mv -v "$T"/widoco_out/provenance "$T"/widoco_out/"$ontfname_frag"-provenance
        mv -v "$T"/widoco_out/index-en.html "$T"/widoco_out/"$ontfname".html
    } 2>&1 >&3 | sed -e "s|^|[${pathname}:E] |" >&2; } 3>&1 | sed -e "s|^|[${pathname}:O] |" &
done

######################
wait
######################

for pathname in "${target_paths[@]}"; do
    echo "... merging $pathname ..." >&2
    T="$T0/$pathname"
    rsync -a "$T"/widoco_out// "$T0"/widoco_master//
done

# add coypu style
cat <<CSS >> "$T0"/widoco_master/resources/extra.css
html { font-size: 14px !important; scroll-behavior: smooth; }

@media (min-width: 31.25rem) { html { font-size: 16px !important; } }

body { font-family: "Red Hat Display", sans-serif; font-size: inherit; line-height: 1.4; color: #5c5962; background-color: #fff; overflow-wrap: break-word; padding: 1em; }

@media (min-width: 31.25rem) { body { padding: 1em 2em; } }

h1 { font-size: 32px !important; line-height: 1.25; font-weight: 300; }

@media (min-width: 31.25rem) { h1 { font-size: 36px !important; } }

h2 { font-size: 18px !important; }

@media (min-width: 31.25rem) { h2 { font-size: 24px !important; line-height: 1.25; } }

h3 { font-size: 16px !important; }

@media (min-width: 31.25rem) { h3 { font-size: 18px !important; } }

h4 { font-size: 11px !important; font-weight: 400; text-transform: uppercase; letter-spacing: 0.1em; }

@media (min-width: 31.25rem) { h4 { font-size: 12px !important; } }

h5 { font-size: 12px !important; }

@media (min-width: 31.25rem) { h5 { font-size: 14px !important; } }

h6 { font-size: 11px !important; }

@media (min-width: 31.25rem) { h6 { font-size: 12px !important; } }

::selection { color: #fff; background: #005c83; }

a { color: #005c83; text-decoration: none; }

a:not([class]) { text-decoration: underline; text-decoration-color: #eeebee; text-underline-offset: 2px; }

a:not([class]):hover { text-decoration-color: rgba(0, 92, 131, 0.45); }

tt, code { font-family: "Red Hat Mono", monospace; font-size: 0.75em; line-height: 1.4; }

a:hover, a:focus { color: #ed8b00; }

a:not([class]):hover, a:not([class]):focus { text-decoration-color: rgba(237, 139, 0, 0.45); }

h1, h2, h3, h4, h5, h6, .section-heading { font-family: "Red Hat Display", sans-serif; font-weight: 900; }

tt, code { font-size: 13.6px; }

:not(pre, figure) > code { padding: 0 0.15em 0.1em; }

/* red-hat-display-regular - latin */
@font-face { font-family: 'Red Hat Display'; font-style: normal; font-weight: 400; src: url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-regular.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-regular.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-regular.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-regular.woff") format("woff"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-regular.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-regular.svg#RedHatDisplay") format("svg"); /* Legacy iOS */ }

/* red-hat-display-500 - latin */
@font-face { font-family: 'Red Hat Display'; font-style: normal; font-weight: 500; src: url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500.woff") format("woff"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500.svg#RedHatDisplay") format("svg"); /* Legacy iOS */ }

/* red-hat-display-900 - latin */
@font-face { font-family: 'Red Hat Display'; font-style: normal; font-weight: 900; src: url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900.woff") format("woff"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900.svg#RedHatDisplay") format("svg"); /* Legacy iOS */ }

/* red-hat-display-italic - latin */
@font-face { font-family: 'Red Hat Display'; font-style: italic; font-weight: 400; src: url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-italic.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-italic.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-italic.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-italic.woff") format("woff"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-italic.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-italic.svg#RedHatDisplay") format("svg"); /* Legacy iOS */ }

/* red-hat-display-500italic - latin */
@font-face { font-family: 'Red Hat Display'; font-style: italic; font-weight: 500; src: url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500italic.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500italic.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500italic.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500italic.woff") format("woff"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500italic.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-500italic.svg#RedHatDisplay") format("svg"); /* Legacy iOS */ }

/* red-hat-display-900italic - latin */
@font-face { font-family: 'Red Hat Display'; font-style: italic; font-weight: 900; src: url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900italic.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900italic.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900italic.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900italic.woff") format("woff"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900italic.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-display/red-hat-display-v7-latin-900italic.svg#RedHatDisplay") format("svg"); /* Legacy iOS */ }

/* red-hat-mono-regular - latin */
@font-face { font-family: 'Red Hat Mono'; font-style: normal; font-weight: 400; src: url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-regular.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-regular.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-regular.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-regular.woff") format("woff"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-regular.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-regular.svg#RedHatMono") format("svg"); /* Legacy iOS */ }

/* red-hat-mono-600 - latin */
@font-face { font-family: 'Red Hat Mono'; font-style: normal; font-weight: 600; src: url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600.woff") format("woff"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600.svg#RedHatMono") format("svg"); /* Legacy iOS */ }

/* red-hat-mono-italic - latin */
@font-face { font-family: 'Red Hat Mono'; font-style: italic; font-weight: 400; src: url("../red-hat-mono/font/red-hat-mono-v3-latin-italic.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-italic.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-italic.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-italic.woff") format("woff"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-italic.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-italic.svg#RedHatMono") format("svg"); /* Legacy iOS */ }

/* red-hat-mono-600italic - latin */
@font-face { font-family: 'Red Hat Mono'; font-style: italic; font-weight: 600; src: url("//coypu.org/assets/font/red-hat-mono-v3-latin-600italic.eot"); /* IE9 Compat Modes */ src: local(""), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600italic.eot?#iefix") format("embedded-opentype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600italic.woff2") format("woff2"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600italic.woff") format("woff"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600italic.ttf") format("truetype"), url("//coypu.org/assets/font/red-hat-mono/red-hat-mono-v3-latin-600italic.svg#RedHatMono") format("svg"); /* Legacy iOS */ }
CSS

echo "</dl><p><small><i>Last update: $(LANG=C TZ=UTC date)</i> <i>Git version: $(LANG=C git rev-parse --short HEAD)</i></small>" >> "$T0"/widoco_master/index.html
if [[ -d dataset-stats/.git ]]; then
    echo " <small><i>(usage stats: $(LANG=C TZ=UTC git -C dataset-stats/ log -1 --format=%cd --date=short))</i></small>" >> "$T0"/widoco_master/index.html
fi

rm -fr widoco_master.old || :
mv widoco_master widoco_master.old 2>/dev/null || :
mv "$T0"/widoco_master .

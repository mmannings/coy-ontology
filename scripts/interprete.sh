#!/bin/bash

echo "Now in interprete.sh"

# filter RDFUnit report
cat ./RDFUnit_results.jsonld | jq '.["@graph"] | .[] | select(.testCase )'  | jq -c 'select(.["message"] != "http://www.w3.org/2000/01/rdf-schema#label is missing proper range") | select(.["message"] != "http://www.w3.org/2000/01/rdf-schema#comment is missing proper range") | (.["severity"]), (.["message"]), (.["focusNode"])' > RDFUnit_errors_.txt
cat ./RDFUnit_manual_results.jsonld | jq '.["@graph"] | .[] | select(.testCase )'  | jq -c '(.["severity"]), (.["message"]), (.["focusNode"])' > RDFUnit_manual_errors_.txt

# filter OOPS report
echo "Now filter OOPS report"
# First read OOPS results
sh -c " cat ./oops_result.xml | xq -c '.[\"rdf:RDF\"] | .[\"rdf:Description\"] |  map( select( [ .[\"oops:hasImportanceLevel\"] | .[\"#text\"] == \"Critical\" ] | any )? )' | jq -c '.[] | (.[\"oops:hasNumberAffectedElements\"] | .[\"#text\"]), (.[\"oops:hasDescription\"] | .[\"#text\"])'" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\<br\>/g' > critical.txt
sh -c " cat ./oops_result.xml | xq -c '.[\"rdf:RDF\"] | .[\"rdf:Description\"] |  map( select( [ .[\"oops:hasImportanceLevel\"] | .[\"#text\"] == \"Important\" ] | any )? )' | jq -c '.[] | (.[\"oops:hasNumberAffectedElements\"] | .[\"#text\"]), (.[\"oops:hasDescription\"] | .[\"#text\"])'" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\<br\>/g' > important.txt
sh -c " cat ./oops_result.xml | xq -c '.[\"rdf:RDF\"] | .[\"rdf:Description\"] |  map( select( [ .[\"oops:hasImportanceLevel\"] | .[\"#text\"] == \"Minor\" ] | any )? )' | jq -c '.[] | (.[\"oops:hasNumberAffectedElements\"] | .[\"#text\"]), (.[\"oops:hasDescription\"] | .[\"#text\"])'" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\<br\>/g' > minor.txt

# Preparation of files
entries_manual=$(expr $(awk 'END{print NR}'  RDFUnit_manual_errors_.txt) / 3)
entries_auto=$(expr $(awk 'END{print NR}'  RDFUnit_errors_.txt) / 3)

# Put everything into one file
echo "Now big command"
echo "OOPS Summary: (always the occurrences amount and then the description; if they are empty, then either there are no pitfalls relevant or the file has syntax issues) <i><br> Critical: <br> " `cat critical.txt` " <br>  <br> Important: <br> " `cat important.txt` " <br>  <br> Minor: <br> " `cat minor.txt` " </i><br>  <br>  <br>" > reports_.txt
echo "RDFUnit Summary ($entries_manual warning or errors) - first from manual tests: (Always the issue level, then the description and then the URI with the problem.)<br><i>" >> reports_.txt
cat RDFUnit_manual_errors_.txt | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\<br\>/g' >> reports_.txt
echo "<br><br></i>Now the automatically created tests ($entries_auto warnings or errors):<br><i>" >> reports_.txt
cat RDFUnit_errors_.txt | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\<br\>/g' >> reports_.txt
echo "</i>" >> reports_.txt
cat reports_.txt | sed -e 's/"//g' > reports__.txt
tr -d '\n' < reports__.txt > reports.txt

# Now read RDFUnit report
echo "Now Reading report if errors exist in manual tests"
cat RDFUnit_manual_errors_.txt | grep "rlog:ERROR" > RDFUnit_manual_errors_temp.txt
lines=$(awk 'END{print NR}' RDFUnit_manual_errors_temp.txt)
if [ $lines -gt 0 ]; then
	cat RDFUnit_manual_errors_.txt
	exit 1
fi

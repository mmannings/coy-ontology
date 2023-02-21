# RDFUnit test cases

## Rules to check

### Graph IRIs should end with a ```/```.

### Name classes in UpperCamelCase.

### Names should be expressive but should not include *class* or *property*.

### Name relations in lowerCamelCase and prefixe them with *has*. <- Claus muss mir helfen

### If there is a relation <> inverse-relation pair, the inverse relation should be prefixed with *is* and suffixed with *Of*.

### Specify the language of all annotations, eg. [language: en].

### An ontology should be defined as a owl:Ontology and should include metadata like rdfs:comment, dct:creator, rdfs:label, owl:versionInfo, dct:modified, owl:priorVersion and properties from [PURL](http://purl.org/vocab/vann/).

## Hints

Execute a test locally:

```
docker run --rm --entrypoint="" -it -v .../rdfunit-tests/:/tests -v ...:/data aksw/rdfunit java -jar /app/rdfunit-validate.jar -A -v -d /data/main.ttl -s /tests/rdfunit-classes-camel-case.ttl -o junitxml -C -f /data/
```

# Automated mappings in CoyPu project

This folder contains explanation of a mapping between 
[International Standard Industrial Classification of all Economic Activities (ISIC) Rev 4](https://www.fao.org/statistics/caliper/tools/download/en) and 
[Trade in Value Added (TIVA)](https://www.oecd.org/sti/ind/measuring-trade-in-value-added.htm) classification schemas workflow. 
Mapping is generated automatically using [LogMap matcher tool](https://git.tib.eu/terminology/sandbox/logmap-matcher) and [RDFizer](https://github.com/SDM-TIB/SDM-RDFizer) tools.

## Mappings between ISIC-4 and TIVA-21 classifications

Producing and validating the mapping between ISIC Rev 4 and TIVA 21 classifications workflow is depicted in Figure 1. 
The workflow consists of the following five steps: 

---
1. Create SKOS vocabulary from ISIC rev 4 csv file.
2. Create SKOS vocabulary from TIVA-21 classification.
3. Produce mappings between TIVA 21 and ISIC rev 4 (csv file).
4. Generate TTL file of mappings between TIVA 21 to ISIC Rev 4.
5. Mapping graph validation
---

#### Step1: Create SKOS vocabulary from ISIC rev 4 csv file
The ISIC Rev 4 classification schema is downloaded as a csv file from [this](https://www.fao.org/statistics/caliper/tools/download/en) page. 
The ISIC4-core.csv file is available in **isic-rev4-data** folder within this git repository.
 The [RDFizer](https://github.com/SDM-TIB/SDM-RDFizer) is used to generate TTL file from the csv file. 
 TDFizer mapping file **isic4_csv_to_ttl_mappings.ttl** is available in the **logmap-mappings** folder of this git repository.
 The resulting **isic4_data.ttl** file is available in **mapping** folder of this repository. 
Each node in the ISIC Rev 4 graph is instance of a **skos:Concept**. 
The [SCHAL](https://github.com/TopQuadrant/shacl) engine is used to validate ISIC Rev 4 graph 
against SKOS shapes when running the following command

```
./shaclvalidate.sh -datafile isic4_data.ttl -shapesfile skos.shapes.ttl
```
If the isic4_data.ttl does not pass SCHAL engine validation then all issues should be fixed 
in the graph before using it in producing mappings between ISIC Rev 4 and TIVA classificaitons.

| ![Mapping workflow](workflow-of-producing-mappings-between-tiva21-and-isic4.png) | 
|:--:| 
| *Figure 1. Mapping between ISIC rev 4 and TIVA 21 classifications workflow* |

#### Step 2: Create SKOS vocabulary from TIVA-21 classification

To prepare the TIVA classification for mappings as а starting point we use [Guide to OECD TiVA Indicators, 2021 edition](https://www.oecd-ilibrary.org/science-and-technology/guide-to-oecd-tiva-indicators-2021-edition_58aa22b1-en).
Similar to the fist step, TIVA classification is created by using **Table A.3. Industry coverage** from page 53 of the TIVA guide. 
Created **tiva-21.ttl** file is available in **mapping** folder of this git repository.  
SHACL engine is used to validate generated TIVA graph  against skos shapes by running the following command:
```
./shaclvalidate.sh -datafile tiva-21.ttl -shapesfile skos.shapes.ttl
```
As in Step 1, if TIVA graph does not pass validation then all issues should be resolved before using TIVA graph in producing mappings between TIVA and ISIC Rev 4 classifications.

#### Step 3: Produce mappings between TIVA 21 and ISIC rev 4 (csv file)

To produce semantic mappings between ISIC Rev 4 and TIVA SKOS classifications the [LogMap](https://git.tib.eu/terminology/sandbox/logmap-matcher) matcher tool is used. 
Java code that runs LogMap is available within the LogMap project. Input ontologies for the mapping are TTL file created in Step 1 and Step 2, i.e. **isic4_data.ttl** and **tiva-21.ttl** files respectively.
To generate mappings one should run *MappingsBetweenIsicAndTiva.java* file located in *test* folder of the LogMap project. 
Output of the mapping is a csv file that contains the following data:

- **source_iri**: IRI for ISIC Rev 4 instances of SKOS concept.
- **target_iri**:  IRI for TIVA instances of SKOS concept.
- **type_of_mapping**: is a number that denotes whether mapping between source and target resources is classes mapping, or mappings between properties or individuals. 
In this case type of mapping is equal to number 3. It denotes mappings between individuals, i.e. instances of SKOS concept.
- **mappings_direction**: is a number that denotes relations between source iri and target iri such as equivalence, same as, subsumption of or disjoint relations.
- **mapping_confidence**: is a number that is in the range \[0,1\]. It denotes level of confidence for produced relations between source iri and target iri.

Result of mapping is saved in **mappings-between-isic4-and-tiva-21.csv** file that is available in **logmap-mappings** folder of this git repository.

#### Step 4: Generate TTL file of mappings between TIVA 21 to ISIC rev 4

RDFizer is used to transform **mappings-between-isic4-and-tiva-21.csv** file into corresponding ttl file. The **mappings-between-isic4-and-tiva-21.ttl** file is available in 
**logmap-mappings** folder of this git repository. 

#### Step 5: Mapping graph validation

All generated graphs in this folder are vadalited  against SKOS shapes by using SHACL engine. The **mappings-between-isic4-and-tiva-21.ttl** graph 
is validated by running the following command:
```
./shaclvalidate.sh -datafile mappings-between-isic4-and-tiva-21.ttl -shapesfile skos.shapes.ttl
```
Below is a report when SHACL engine vlidates gaprah sucessfuly.
```
@prefix :          <https://data.coypu.org/mappings/tiva2isic#> .
@prefix dash:      <http://datashapes.org/dash#> .
@prefix graphql:   <http://datashapes.org/graphql#> .
@prefix isic:      <https://data.coypu.org/classification/isic_r4/> .
@prefix owl:       <http://www.w3.org/2002/07/owl#> .
@prefix ql:        <http://semweb.mmlab.be/ns/ql#> .
@prefix rdf:       <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:      <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rml:       <http://semweb.mmlab.be/ns/rml#> .
@prefix rr:        <http://www.w3.org/ns/r2rml#> .
@prefix sh:        <http://www.w3.org/ns/shacl#> .
@prefix skos:      <http://www.w3.org/2004/02/skos/core#> .
@prefix swa:       <http://topbraid.org/swa#> .
@prefix tiva-21:   <https://data.coypu.org/classification/tiva-21> .
@prefix tiva2isic: <https://data.coypu.org/mappings/tiva2isic#> .
@prefix tosh:      <http://topbraid.org/tosh#> .
@prefix xsd:       <http://www.w3.org/2001/XMLSchema#> .

[ rdf:type     sh:ValidationReport ;
  sh:conforms  true
] .
```

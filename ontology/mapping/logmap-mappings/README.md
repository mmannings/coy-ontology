# Automated mappings in CoyPu project

This folder contains explanation of a mapping between 
[International Standard Industrial Classification of all Economic Activities (ISIC) Rev 4](https://www.fao.org/statistics/caliper/tools/download/en) and 
[Trade in Value Added (TIVA)](https://www.oecd.org/sti/ind/measuring-trade-in-value-added.htm) classification schemas workflow. 
Mapping is generated automatically using [LogMap matcher tool](https://git.tib.eu/terminology/sandbox/logmap-matcher) and [RDFizer](https://github.com/SDM-TIB/SDM-RDFizer) tools.

## Mappings between ISIC-4 and TIVA-21 classifications

Producing and validating the mapping between ISIC Rev 4 and TIVA 21 classifications workflow is depicted in Figure 1. 
The workflow consists of the following five steps: 

---
1. Create SKOS vocabulary from ISIC rev 4 classification.
2. Create SKOS vocabulary from TIVA-21 classification.
3. Produce mappings between TIVA 21 and ISIC rev 4 (csv file).
4. Generate TTL file of mappings between TIVA 21 to ISIC rev 4.
5. Graphs Validation reports.
---

The ISIC Rev 4 classification is downloaded as a csv file from [this](https://www.fao.org/statistics/caliper/tools/download/en) page. 
The csv file is available in [isic-rev4-data](https://gitlab.com/coypu-project/coy-ontology/-/tree/93-automated-mappings-between-isic4-and-tiva/ontology/mapping/logmap-mappings/isic-rev4-data?ref_type=heads) folder.
The RDFizer is used to generate **isic4_data**  TTL file from the csv file. The TTL file is available in **mapping** folder of this repository. 
Each node in the ISIC Rev 4 graph is instance of a **skos:Concept** as well as instance of **rdfs:Class**. The SCHAL engine is used to validate


 
| ![Mapping workflow](workflow-of-producing-mappings-between-tiva21-and-isic4.png) | 
|:--:| 
| *Figure 1. Mapping between ISIC rev 4 and TIVA 21 classifications workflow* |


## Notes
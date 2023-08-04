# Automated mappings in CoyPu project

This folder contains explanation of a mapping between [International Standard Industrial Classification of all Economic Activities (ISIC) Rev 4](https://www.fao.org/statistics/caliper/tools/download/en) and 
[Trade in Value Added](https://www.oecd.org/sti/ind/measuring-trade-in-value-added.htm) classification schemas workflow. 
Mapping is generated automatically using [LogMap matcher tool](https://git.tib.eu/terminology/sandbox/logmap-matcher).

## Mappings between ISIC-4 and TIVA-21 classifications
Producing and validating the mapping between ISIC Rev 4 and TIVA 21 classifications workflow is depicted in Figure 1. 
There are five use case, such as 
---
1. Create SKOS vocabulary from ISIC rev 4 classification.
2. Create SKOS vocabulary from TIVA-21 classification.
3. Produce mappings between TIVA 21 and ISIC rev 4 (csv file).
4. Generate TTL file of mappings between TIVA 21 to ISIC rev 4.
5. Graphs Validation reports.
---
As a fist step to create input TTL files for both ISIC4 and TIVA-21 classification schemas.

 
| ![Mapping workflow](workflow-of-producing-mappings-between-tiva21-and-isic4.png) | 
|:--:| 
| *Figure 1. Mapping between ISIC rev 4 and TIVA 21 classifications workflow* |


## Notes
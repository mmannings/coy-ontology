## Problem statement
Different datasets quite often use different classification schemas to refer to products, sectors, activities and industries. 
In the Coypu project we decided to use `NACE 2` across pipeline and platform.

### Task
Find a way aka mappings from other schemas to `NACE 2`. 

### Status
Writing those mappings by ourself is infeasible, neither are we domain experts, nor do we have enough time to work on this. Luckily, there are some existing mappings aka correspondence tables available on the web:

* UNStats: https://unstats.un.org/unsd/classifications/Econ#Correspondences
* TODO other sources?

#### An overview (taken from a [challenge](https://semstats.org/2016/challenge/classifications)), yellow lines denote existing mappings

![image](/uploads/3600d03d52da8c21a45cd352eaff4468/image.png)
------------------
#### Another view on the different classifications taken from the paper [Taxonomies and Nomenclatures Guidance](https://www.icmagroup.org/assets/documents/Sustainable-finance/Taxonomies-and-Nomenclatures-Guidance-March-2021-18032021.pdf):
##### Economic activity and product nomenclatures in selected parts of the world/user group
![image](/uploads/83b507e842664ef22a45cadac9309eb5/image.png)
------------------
##### An example how those different coding schemes across the same products look like:
![image](/uploads/a3c480839b3b7c5588ff2c3a3769179f/image.png) 
------------------
##### Some additional perspectives on those classifications (not that relevant for us probably):
![image](/uploads/be5cff2bd42450965e30c3b4078acf26/image.png)


### NACE Rev. 2
* [NACE Rev. 2](https://ec.europa.eu/eurostat/web/nace-rev2/overview) (Statistical Classification of Economic Activities in the European Community) is the classification of economic activities in the European Union (EU)
* European version of ISIC (International Standard Industrial Classification of All Economic Activities), Rev. 4, which is a global classification of economic activities maintained by the United Nations
* intially hosted by Eurostat on RAMON platform, but recently (2022-07-14) moved most of the data to a newer platform [EU Vocabularies](https://op.europa.eu/en/web/eu-vocabularies/dataset/-/resource?uri=http://publications.europa.eu/resource/dataset/nace2)
* the movement to vocabularies also results in an RDF resp. [SKOS/XKOS dataset](https://op.europa.eu/en/web/eu-vocabularies/dataset/-/resource?uri=http://publications.europa.eu/resource/dataset/nace2#_eu_europa_publications_portlet_conceptdisplay_ConceptDisplayPortlet_14TabContent) being provided instead of good old [XML/CSV](https://ec.europa.eu/eurostat/ramon/nomenclatures/index.cfm?TargetUrl=LST_CLS_DLD&StrNom=NACE_REV2&StrLanguageCode=EN&StrLayoutCode=HIERARCHIC)
* the advantage i) it's already RDF and ii) it's multi-lingual

An example from the RDF SKOS taxonomy taken with

``` sparql
CONSTRUCT {
        ?s ?p ?o
} WHERE {
        BIND(<http://data.europa.eu/ux2/nace2/0119> AS ?s)
        ?s ?p ?o .
        filter( isURI(?o) || lang(?o) = '' || lang(?o) = 'en')
}
```


``` turtle
@prefix :         <http://data.europa.eu/ux2/nace2/> .
@prefix rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix skos:     <http://www.w3.org/2004/02/skos/core#> .
@prefix xkos:     <http://rdf-vocabulary.ddialliance.org/xkos#> .

:0119   rdf:type              skos:Concept ;
        xkos:coreContentNote  "This class includes the growing of all other non-perennial crops:\n- growing of swedes, mangolds, fodder roots, clover, alfalfa, sainfoin, fodder maize and other grasses, forage kale and similar forage products \n- growing of beet seeds (excluding sugar beet seeds) and seeds of forage plants\n- growing of flowers\n- production of cut flowers and flower buds\n- growing of flower seeds"@en ;
        xkos:exclusionNote    "This class excludes:\n- growing of non-perennial spices, aromatic, drug and pharmaceutical crops, see 01.28"@en ;
        skos:altLabel         "Growing of other non-perennial crops"@en ;
        skos:broader          :011 ;
        skos:inScheme         :nace2 ;
        skos:notation         "01.19"^^rdf:PlainLiteral ;
        skos:prefLabel        "01.19 Growing of other non-perennial crops"@en .
```
(That is technically exactly like I created it from the CSV file (except for the namespace of course).)

As stated, there is a direct correspondence to ISIC r4 which is also contained in the RDF data and modelled via XKOS:

``` sparql
PREFIX xkos: <http://rdf-vocabulary.ddialliance.org/xkos#>
CONSTRUCT {
        ?ass a xkos:ConceptAssociation ; 
             xkos:sourceConcept ?s ; 
             xkos:targetConcept ?t 
} WHERE {
        BIND(<http://data.europa.eu/ux2/nace2/0119> AS ?s)
        ?ass a xkos:ConceptAssociation ;
             xkos:sourceConcept ?s ;
             xkos:targetConcept ?t
}

```

``` turtle
:NACE2_ISIC4_10  rdf:type   xkos:ConceptAssociation ;
        xkos:sourceConcept  :0119 ;
        xkos:targetConcept  <http://stats-class.fao.uniroma2.it/ISIC/rev4/0119> .

```

### Example
In the Global Trade Alerts dataset `CPC 2.1` is used for products and `HS 2012` for sectors.

So our goal is to get from 

* `CPC 2.1` -> `NACE 2`
* `HS 2012` -> `NACE 2`

Looking at the figure above, we can see

* a path `CPC 2.1` -> `ISIC 4` -> `NACE 2`
* no entry for `HS 2012`

That said, the figure






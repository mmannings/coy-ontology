# Instructions

How to use the provided industry sectors, activities and products dataset:

## Namespaces and prefixes

* all currently provided classification schemes are provided under base namespace `https://data.coypu.org/classification/`
* a different scheme gets its own namespace, i.e. if you have a scheme and ideally a version, please use the following pattern: 
`https://data.coypu.org/classification/{$scheme_$version}/`

## Currently provided classification schemes

|   Scheme    | Prefix |                     Namespace                     |
|-------------|--------|---------------------------------------------------|
| CPC 2.1     | cpc:   | <https://data.coypu.org/classification/cpc_v2.1/> |
| HS 2012     | hs:    | <https://data.coypu.org/classification/hs_2012/>  |
| NACE Rev. 2 | nace:  | <https://data.coypu.org/classification/nace_r2/>  |
| ISIC Rev. 4 | isic:  | <https://data.coypu.org/classification/isic_r4/>  |

## Currently provided mappings

* provided as SKOS concept relations via `skos:closeMatch` property
* can be `1-1`, `1-n`, `n-1` or `n-n` mappings

|    From     |     To      |
|-------------|-------------|
| HS 2012     | CPC 2.1     |
| CPC 2.1     | ISIC Rev. 4 |
| ISIC Rev. 4 | NACE Rev. 2 |


### Turtle header/SPARQL prefixes

``` SPARQL
PREFIX cpc: <https://data.coypu.org/classification/cpc_v2.1/>
PREFIX hs: <https://data.coypu.org/classification/hs_2012/>
PREFIX nace: <https://data.coypu.org/classification/nace_r2/>
PREFIX isic: <https://data.coypu.org/classification/isic_r4/>

```

## Access to the data

### Turtle data via Gitlab
Download from [here](https://gitlab.com/coypu-project/coy-ontology/-/tree/sectors/sectors/data)

### SPARQL endpoint
At the Implisense CMEM instance query the graph: `https://sectors.coypu.org/classification/`

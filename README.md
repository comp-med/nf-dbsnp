# nf-dbSNP

A nextflow pipeline to download the latest realease of
[dbSNP](https://www.ncbi.nlm.nih.gov/snp/docs/about/) for humans.

## Introduction

The database `dbSNP` contains information on registered genetic polymorphisms
for the whole (human) genome.

## Requirements

### `conda`

Some steps require access to an installation of
[`conda`](https://www.nextflow.io/docs/latest/conda.html) to create
environments with the necessary software. See the directory `conda_envs` for
the specifications.

### `R`

An installation of the [`R` programming language](https://www.r-project.org/)
with the additional library [`polars`](https://pola-rs.github.io/r-polars/) are
required. Additionally, the location of the R package library must be entered
as the parameter `r_lib` in the file `nextflow.config`

## Getting Started

Run the pipeline by entering the required parameters in `nextflow.config` and
setting up the profile for your runtime environment (e.g. your local computer
or HPC) and the start the pipeline.

```bash 
# The basic command
nextflow run main.nf 

# Specify this in `nextflow.config` or as a parameter flag
nextflow run main.nf --r_lib </PATH/TO/YOUR/R/LIBRARY>

# Select a profile if necessary
nextflow run main.nf -profile cluster
```

### Input

The pipeline does not require input files, only the name of the genome build
used for the positions of the variants, which must be either/or `grch37_p13`
and `grch38_p14` and the chromosomes (in UCSC style) to write as output. You
can change these values in the file `nextfow.config`.

### Output

Based on the parameter `outDir` (default ist `./output/`) and the selected
inputs, the pipeline will output `.parquet` files for each chromosome of each
genome build (`GRCh37p13`, `GRCH38p14`). 

```bash
output/
├── grch37_p13
│   ├── dbsnp_grch37_p13_chr1.parquet
│   ├── dbsnp_grch37_p13_chr10.parquet
[...]
│   └── dbsnp_grch37_p13_chrY.parquet
└── grch38_p14
    ├── dbsnp_grch38_p14_chr1.parquet
    ├── dbsnp_grch38_p14_chr10.parquet
[...]
    └── dbsnp_grch38_p14_chrY.parquet
```

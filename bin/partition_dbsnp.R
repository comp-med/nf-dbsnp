#! /usr/bin/env Rscript

# SETUP ----

# parse arguments
args <- commandArgs(trailingOnly = TRUE)
options(stringsAsFactors = FALSE)

# INPUT ----

dbsnp_tsv_file <- args[1]
chrom <- args[2]
r_lib <- args[3]


# LIBRARIES ----

# load packages
r_lib <- "$r_lib"
suppressPackageStartupMessages(library("polars", lib.loc = r_lib))

# MAIN ----

stopifnot(
    "Selected chromosome range must be default UCSC chromsomes chr1-chr22, chrX, chrY" = 
    all(chrom %in% paste0("chr", c(1:22, "X", "Y"))),
    "Input file `dbsnp_tsv_file` does not seem to exist" = 
    file.exists(dbsnp_tsv_file)
)

grch37_map <- pl$scan_csv(dbsnp_tsv_file, separator = "\t", has_header = FALSE)
grch37_map <- grch37_map$filter(pl$col("column_1") == chrom)
grch37_map <- grch37_map$collect()
grch37_map <- grch37_map$set_column_names(
    c("chr_ucsc", "pos", "rs_id", "ref", "alt")
)
grch37_map <- grch37_map$with_columns(
    rs_number = pl$col("rs_id")$str$replace("^rs", ""),
    chr_ensembl = pl$col("chr_ucsc")$str$replace("^chr", "")
)

# Uint32 should be enough here and I think this makes the tables easier to 
# search through compared with having this as String
grch37_map <- grch37_map$cast(rs_number = pl$UInt32, pos = pl$UInt32)
grch37_map <- grch37_map$select(
    "chr_ucsc", "chr_ensembl", "pos", "ref", "alt", "rs_id", "rs_number"
)

# OUTPUT ----

save_file <- "dbsnp_chr.parquet"
grch37_map$write_parquet(save_file)

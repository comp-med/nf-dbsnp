process DOWNLOAD_ASSEMBLY_REPORT {
  // The report contains a table of all chromosomes in different naming styles

  tag "assembly_report: $genome_build"
  label 'bash_process'
  conda 'conda_envs/bash_utils.yml'

  input: 
  val genome_build

  output:
  tuple val(genome_build), file("*.txt")

  script:
  """
  GENOME_BUILD="$genome_build"
  NCBI_FTP="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405"

  if [[ "\$GENOME_BUILD" == "grch37_p13" ]]; then
    LINK="\${NCBI_FTP}/GCF_000001405.25_GRCh37.p13/GCF_000001405.25_GRCh37.p13_assembly_report.txt"
  elif [[ "\$GENOME_BUILD" == "grch38_p14" ]]; then 
    LINK="\${NCBI_FTP}/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_assembly_report.txt"
  fi
  wget \$LINK
  """

  stub:
  """
  GENOME_BUILD="$genome_build"
  if [[ "\$GENOME_BUILD" == "grch37_p13" ]]; then
    touch GCF_000001405.25_GRCh37.p13_assembly_report.txt
  elif [[ "\$GENOME_BUILD" == "grch38_p14" ]]; then 
    touch GCF_000001405.40_GRCh38.p14_assembly_report.txt
  fi
  """
}

process DOWNLOAD_DBSNP_INDEX {
  // Re-naming the chromosomes in the dbSNP VCF requires the index file
  
  tag "dbsnp_index: $genome_build"
  label 'bash_process'
  cache 'lenient'
  conda 'conda_envs/bash_utils.yml'

  input: val genome_build

  output:
  tuple val(genome_build), file("*.gz.tbi")

  script:
  """
  GENOME_BUILD="$genome_build"
  NCBI_FTP="https://ftp.ncbi.nih.gov/snp/latest_release/VCF/"

  if [[ "\$GENOME_BUILD" == "grch37_p13" ]]; then

    LINK="\${NCBI_FTP}/GCF_000001405.25.gz.tbi"

  elif [[ "\$GENOME_BUILD" == "grch38_p14" ]]; then 

    LINK="\${NCBI_FTP}/GCF_000001405.40.gz.tbi"

  fi
  wget \$LINK
  """

  stub:
  """
  GENOME_BUILD="$genome_build"
  if [[ "\$GENOME_BUILD" == "grch37_p13" ]]; then

    touch GCF_000001405.25.gz.tbi

  elif [[ "\$GENOME_BUILD" == "grch38_p14" ]]; then 

    touch GCF_000001405.40.gz.tbi

  fi
  """

}

process DOWNLOAD_DBSNP {
  // TODO: compare checksum to make sure download was complete
  
  tag "dbsnp: $genome_build"
  label 'bash_process'
  cache 'lenient'
  conda 'conda_envs/bash_utils.yml'

  input: val genome_build

  output:
  tuple val(genome_build), file("*.gz")

  script:
  """
  GENOME_BUILD="$genome_build"
  NCBI_FTP="https://ftp.ncbi.nih.gov/snp/latest_release/VCF/"

  if [[ "\$GENOME_BUILD" == "grch37_p13" ]]; then

    LINK="\${NCBI_FTP}/GCF_000001405.25.gz"

  elif [[ "\$GENOME_BUILD" == "grch38_p14" ]]; then 

    LINK="\${NCBI_FTP}/GCF_000001405.40.gz"

  fi
  wget \$LINK
  """

  stub:
  """
  GENOME_BUILD="$genome_build"
  if [[ "\$GENOME_BUILD" == "grch37_p13" ]]; then

    touch GCF_000001405.25.gz 

  elif [[ "\$GENOME_BUILD" == "grch38_p14" ]]; then 

    touch GCF_000001405.40.gz

  fi
  """

}

process CHROM_MAP {
  // Create the mapping file for renaming chromosomes to UCSC style

  tag "chrom_map: $genome_build"
  label 'bash_process'
  conda 'conda_envs/bash_utils.yml'

  input:
  tuple val(genome_build), path(assembly_report)
  
  output: 
  tuple val(genome_build), path("full_chromosome_map.tsv")

  script:
  """
  IN="$assembly_report"
  OUT="full_chromosome_map.tsv"
  awk -F '\t' '!/^#/{print \$7, \$10}' \$IN > \$OUT
  """
  
  stub:
  """
  touch full_chromosome_map.tsv
  """
}

process RENAME_CHROMS {
  // Change chromosome style from Ensembl to UCSC

  tag "rename_chroms: $genome_build"
  label 'bash_process'
  conda 'conda_envs/bcftools.yml'

  input:
  tuple val(genome_build), path(raw_dbsnp), path(raw_dbsnp_tbi), path(chromosome_map)
  
  output: 
  tuple val(genome_build), path("dbsnp.vcf.gz"), path("dbsnp.vcf.gz.tbi")

  script:
  """
  BUILD="$genome_build"
  MAP="$chromosome_map"
  IN="$raw_dbsnp"
  OUT="dbsnp.vcf.gz"
  bcftools annotate --rename-chrs \$MAP --write-index=tbi -Oz -o \$OUT \$IN
  """
  
  stub:
  """
  touch dbsnp.vcf.gz dbsnp.vcf.gz.tbi
  """
}

process FILTER_CHROMS {
  // Only keep default chromosomes 1-22, X, Y

  tag "filter_chroms: $genome_build, chr: $chr"
  label 'bash_process'
  conda 'conda_envs/bcftools.yml'

  input:
  tuple val(genome_build), path(dbsnp), path(dbsnp_index), val(chr)
  
  output: 
  tuple val(genome_build), val(chr), path("default_dbsnp.vcf.gz"), path("default_dbsnp.vcf.gz.tbi")

  script:
  """
  REGION="$chr"
  IN="$dbsnp"
  OUT="default_dbsnp.vcf.gz"
  bcftools view --regions \$REGION --write-index=tbi -Oz -o \$OUT \$IN
  """
  
  stub:
  """
  touch default_dbsnp.vcf.gz default_dbsnp.vcf.gz.tbi
  """
}

process CREATE_TSV {
  // Create a gzipped TSV from the VCF file

  tag "create_tsv: $genome_build, chr: $chr"
  label 'bash_process'
  conda 'conda_envs/bcftools.yml'

  input:
  tuple val(genome_build), val(chr), path(dbsnp), path(dbsnp_index)
  
  output: 
  tuple val(genome_build), val(chr), path("dbsnp.tsv.gz")
  
  script:
  """
  IN="$dbsnp"
  OUT="dbsnp.tsv"
  bcftools norm -m- --no-version -Ou \$IN | \
  bcftools query \
    -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\n' \
    -o \$OUT
  bgzip \$OUT
  """

  stub:
  """
  touch dbsnp.tsv.gz
  """
}

process CREATE_PARQUET {
  // Add some descriptive column names and save as parquet file

  tag "create_chunks: $genome_build, chr: $chr"
  label 'r_process'
  
  publishDir (
    path: { "${params.outDir}/${genome_build}/" },
    mode: 'copy',
    pattern: 'dbsnp_chr.parquet',
    saveAs: { _filename ->
        "dbsnp_${genome_build}_${chr}.parquet"
    }
  )

  input:
  tuple val(genome_build), val(chr), path(dbsnp), path(r_lib)

  output:
  path "dbsnp_chr.parquet"

  script:
  """
  partition_dbsnp.R $dbsnp $chr $r_lib
  """

  stub:
  """
  touch dbsnp_chr.parquet
  """
}

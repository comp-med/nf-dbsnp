include { 
   DOWNLOAD_ASSEMBLY_REPORT;
   DOWNLOAD_DBSNP;
   CHROM_MAP;
   RENAME_CHROMS;
   FILTER_CHROMS;
   CREATE_TSV;
   PARTITION_DBSNP;

} from '../modules/download_and_process.nf'

workflow DOWNLOAD_AND_PROCESS {

    take: 
    genome_build_ch;
    output_chroms_ch

    main:
    def assembly_report_ch = DOWNLOAD_ASSEMBLY_REPORT(genome_build_ch)
    def raw_dbsnp_ch       = DOWNLOAD_DBSNP(genome_build_ch)
    def dbsnp_ch           = raw_dbsnp_ch.join(assembly_report_ch)
    dbsnp_ch       = CHROM_MAP(dbsnp_ch)
    dbsnp_ch = RENAME_CHROMS(dbsnp_ch)
    dbsnp_ch = FILTER_CHROMS(dbsnp_ch)
    dbsnp_ch = CREATE_TSV(dbsnp_ch)
    PARTITION_DBSNP(dbsnp_ch.combine(output_chroms_ch))

}

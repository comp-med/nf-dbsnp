#!/usr/bin/env nextflow

// https://sydney-informatics-hub.github.io/template-nf-guide/
nextflow.enable.dsl=2

// HEADER ---------------------------------------------------------------------

log.info """\
===============================================================================
Download and Process the latest dbSNP release
===============================================================================

Created by the Computational Medicine Group | BIH @ Charité

===============================================================================
Workflow run parameters 
===============================================================================
input       : ${params.input}
outDir      : ${params.outDir}
workDir     : ${workflow.workDir}
===============================================================================

"""

// Help function
def helpMessage() {
  log.info"""
  Usage:  nextflow run main.nf 

  Required Arguments:

  <TODO>

  Optional Arguments:

  --outDir	Specify path to output directory. Default is `output/`
	
""".stripIndent()
}

// MODULES --------------------------------------------------------------------

include { DOWNLOAD_AND_PROCESS } from './workflows/download_and_process.nf'

// WORKFLOW -------------------------------------------------------------------

workflow {

  // Define input 
  def genome_build_ch = Channel.of(params.input).flatten()
  def output_chroms_ch = Channel.of(params.chromosomes ).flatten()
  def r_lib_ch = Channel.of(params.r_lib)
  
  // Run main workflow
  DOWNLOAD_AND_PROCESS (
    genome_build_ch,
    output_chroms_ch,
    r_lib_ch
  )

}

// SUMMARY --------------------------------------------------------------------

workflow.onComplete {
summary = """
===============================================================================
Workflow execution summary
===============================================================================

Duration    : ${workflow.duration}
Success     : ${workflow.success}
workDir     : ${workflow.workDir}
Exit status : ${workflow.exitStatus}
outDir      : ${params.outDir}

===============================================================================
"""
println summary
}

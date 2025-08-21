#!/usr/bin/env nextflow

// https://sydney-informatics-hub.github.io/template-nf-guide/
nextflow.enable.dsl=2

// HEADER ---------------------------------------------------------------------

def startupMsg() {
  log.info """\
  ===============================================================================
  Download and Process the latest dbSNP release
  ===============================================================================

  Created by the Computational Medicine Group | BIH @ Charité

  ===============================================================================
  Workflow run parameters 
  ===============================================================================
  input       : ${params.input}
  chromosomes : ${params.chromosomes}
  r_lib       : ${params.r_lib}
  outDir      : ${params.outDir}
  workDir     : ${workflow.workDir}
  ===============================================================================

  """.stripIndent()
}

// SUMMARY --------------------------------------------------------------------

// workflow.onComplete 
def completionMsg() {
  log.info """
  ===============================================================================
  Workflow execution summary
  ===============================================================================

  Duration    : ${workflow.duration}
  Success     : ${workflow.success}
  workDir     : ${workflow.workDir}
  Exit status : ${workflow.exitStatus}
  outDir      : ${params.outDir}

  ===============================================================================
  """.stripIndent()
}

// Help function
def helpMessage() {
  log.info"""
  Usage:  nextflow run main.nf 

  Required Arguments:

  --r_lib         Specify the location of your local R package library

  Optional Arguments:

  --input       Default is ['grch37_p13', 'grch38_p14']
  --chromosomes In UCSC style. Default is all chromosomes
  --outDir	Specify path to output directory. Default is `output/`
	
""".stripIndent()
}

// MODULES --------------------------------------------------------------------

include { DOWNLOAD_AND_PROCESS } from './workflows/download_and_process.nf'

// WORKFLOW -------------------------------------------------------------------

workflow {

  startupMsg()
  if ( params.r_lib == null ) {
    helpMessage()
    exit 1
  }

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

// TODO: Move this inside the workflow as suggested here:
// https://www.nextflow.io/docs/latest/notifications.html#completion-handler
// As of 2025-08-21, this does not work and the LSP shows an error for this 
// solution, but it works
workflow.onComplete {
  completionMsg()
}


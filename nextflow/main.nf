#!/usr/bin/env nextflow

//
// bat-mitogenome: assemble a bat mitochondrial genome from Oxford Nanopore
// reads and identify the species. Nextflow port of the original SLURM workflow.
//

include { MITOGENOME_ASSEMBLY } from './subworkflows/local/mitogenome_assembly/main.nf'

workflow {
    if (!params.input) {
        error "No input provided. Use --input <samplesheet.csv> (columns: sample,fastq,mito_reference)."
    }

    ch_samples = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.sample || !row.fastq || !row.mito_reference) {
                error "Samplesheet row is missing a required column (sample, fastq, mito_reference): ${row}"
            }
            def meta = [ id: row.sample, single_end: true ]
            [ meta, file(row.fastq, checkIfExists: true), file(row.mito_reference, checkIfExists: true) ]
        }

    MITOGENOME_ASSEMBLY(ch_samples)
}

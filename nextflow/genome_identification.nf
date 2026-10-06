#!/usr/bin/env nextflow

// Include modules
include { porechop } from './modules/porechop.nf'
include { fastplong } from './modules/fastplong.nf'
include { minimap_seqtk } from './modules/minimap_seqtk.nf'
include { flye_assembly } from './modules/flye_assembly.nf'
include { racon_polish } from './modules/porechop.nf'
include { mitoz } from './modules/mitoz.nf'
include { blast } from './modules/blast.nf'

/*
 * Pipeline parameters
 */
params {
    input_reads: Path = "00_rawReads_bat869.fastq"
    refrence_genome: Path = "MN125184.1_mito.fasta"
}


workflow {

    main:
    // 1. Initialize input channels
    reads_ch = Channel.fromPath(params.input_reads, checkIfExists: true)
    ref_ch = Channel.fromPath(params.reference_genome, checkIfExists: true)

    // 2. Adapter Trimming & Post-Trimming QC
    trimmed_ch = PORECHOP(reads_ch)
    QC_PORECHOP(reads_ch, trimmed_ch.fastq)
    
    // 3. Quality Filtering & Post-Filtering QC
    clean_ch = FASTPLONG(trimmed_ch.fastq)
    QC_FASTPLONG(reads_ch, trimmed_ch.fastq, clean_ch.fastq)
    
    // 4. Connect the remaining assembly steps
    enriched_reads_ch = MINIMAP_SEQTK(clean_ch.fastq, ref_ch)
    draft_assembly_ch = FLYE_ASSEMBLY(enriched_reads_ch.fastq)
    polished_assembly_ch = RACON_POLISH(draft_assembly_ch.fasta, enriched_reads_ch.fastq)
    
    // 5. Run final analyses in parallel on the polished assembly
    MITOZ(polished_assembly_ch.fasta)
    BLAST(polished_assembly_ch.fasta)

    publish:
    
}

output {
    first_output {
        path 'hello_config/intermediates'
        mode 'copy'
    }

}

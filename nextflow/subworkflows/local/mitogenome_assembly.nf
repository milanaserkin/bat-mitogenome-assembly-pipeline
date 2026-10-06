//
// Bat mitochondrial genome assembly & species identification.
// raw reads -> trim -> filter -> reference-guided read extraction ->
// Flye min-overlap sweep -> best-assembly selection -> Racon polishing ->
// MitoZ annotation + remote BLAST, with QC at each stage.
//

include { PORECHOP_PORECHOP }              from '../../../modules/nf-core/porechop/porechop/main.nf'
include { FASTPLONG }                       from '../../../modules/nf-core/fastplong/main.nf'
include { MINIMAP2_ALIGN as MINIMAP2_EXTRACT } from '../../../modules/nf-core/minimap2/align/main.nf'
include { SEQTK_SUBSEQ }                    from '../../../modules/nf-core/seqtk/subseq/main.nf'
include { FLYE }                            from '../../../modules/nf-core/flye/main.nf'

include { PAF_TO_READIDS }                  from '../../../modules/local/paf_to_readids/main.nf'
include { SELECT_BEST_ASSEMBLY }            from '../../../modules/local/select_best_assembly/main.nf'
include { READ_QC }                         from '../../../modules/local/read_qc/main.nf'
include { ASSEMBLY_METRICS }                from '../../../modules/local/assembly_metrics/main.nf'
include { MITOZ_ANNOTATE }                  from '../../../modules/local/mitoz_annotate/main.nf'
include { BLASTN_REMOTE }                   from '../../../modules/local/blastn_remote/main.nf'

include { POLISH_RACON }                    from '../polish_racon/main.nf'

workflow MITOGENOME_ASSEMBLY {
    take:
    ch_samples   // channel: [ val(meta), path(fastq), path(mito_reference) ]

    main:
    ch_raw = ch_samples.map { meta, fastq, reference -> [ meta, fastq ] }
    ch_ref = ch_samples.map { meta, fastq, reference -> [ meta, reference ] }

    // 1. Adapter trimming (Porechop)
    PORECHOP_PORECHOP(ch_raw)

    // 2. Quality/length filtering (fastplong) -> emits cleaned reads + HTML/JSON QC
    FASTPLONG(PORECHOP_PORECHOP.out.reads, [], false, false)
    ch_clean = FASTPLONG.out.reads

    // Read QC: seqkit stats across raw -> trimmed -> cleaned + adapter/short-read checks
    ch_read_qc = ch_raw
        .join(PORECHOP_PORECHOP.out.reads)
        .join(ch_clean)
        .map { meta, raw, trimmed, clean -> [ meta, raw, trimmed, clean ] }
    READ_QC(ch_read_qc)

    // 3. Map cleaned reads to the related mitochondrial reference (PAF)
    MINIMAP2_EXTRACT(ch_clean, ch_ref, false, [], false, false)

    // 4. Keep read IDs with a sufficiently long alignment, then extract those reads
    PAF_TO_READIDS(MINIMAP2_EXTRACT.out.paf)
    ch_extract = ch_clean.join(PAF_TO_READIDS.out.readids)
    SEQTK_SUBSEQ(
        ch_extract.map { meta, clean, ids -> [ meta, clean ] },
        ch_extract.map { meta, clean, ids -> ids }
    )
    ch_mito_reads = SEQTK_SUBSEQ.out.sequences

    // 5. Flye assembly sweep over min-overlap values (fan-out)
    ch_overlaps = channel.fromList(params.flye_min_overlaps)
    ch_flye_in = ch_mito_reads
        .combine(ch_overlaps)
        .map { meta, reads, overlap -> [ meta + [ overlap: overlap ], reads ] }
    FLYE(ch_flye_in, '--nano-raw')

    // 6. Collect the sweep per sample (drop the overlap key) and pick the best assembly
    ch_fa = FLYE.out.fasta
        .map { meta, fasta -> [ meta.findAll { k, v -> k != 'overlap' }, fasta ] }
        .groupTuple()
    ch_info = FLYE.out.txt
        .map { meta, txt -> [ meta.findAll { k, v -> k != 'overlap' }, txt ] }
        .groupTuple()
    SELECT_BEST_ASSEMBLY(ch_fa.join(ch_info))

    // 7. Iterative Racon polishing (3 rounds)
    POLISH_RACON(SELECT_BEST_ASSEMBLY.out.fasta, ch_mito_reads)
    ch_polished = POLISH_RACON.out.polished

    // 8. Assembly metrics (length, N50, GC%)
    ASSEMBLY_METRICS(ch_polished)

    // 9. Annotation (MitoZ) and species identification (remote BLAST) — toggleable
    ch_gbf   = channel.empty()
    ch_blast = channel.empty()
    if (params.run_mitoz) {
        MITOZ_ANNOTATE(ch_polished)
        ch_gbf = MITOZ_ANNOTATE.out.gbf
    }
    if (params.run_blast) {
        BLASTN_REMOTE(ch_polished)
        ch_blast = BLASTN_REMOTE.out.txt
    }

    emit:
    clean_reads   = ch_clean
    mito_reads    = ch_mito_reads
    best_assembly = SELECT_BEST_ASSEMBLY.out.fasta
    polished      = ch_polished
    metrics       = ASSEMBLY_METRICS.out.metrics
    read_qc       = READ_QC.out.qc
    annotation    = ch_gbf
    blast         = ch_blast
}

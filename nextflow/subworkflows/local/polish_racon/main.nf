//
// Iterative long-read polishing: (minimap2 -> racon) x N rounds.
// N is fixed at 3, mirroring the original SLURM workflow. Each round remaps the
// reads against the current consensus and feeds the alignment back into Racon.
//

include { MINIMAP2_ALIGN as MINIMAP2_POLISH1 } from '../../../modules/nf-core/minimap2/align/main.nf'
include { MINIMAP2_ALIGN as MINIMAP2_POLISH2 } from '../../../modules/nf-core/minimap2/align/main.nf'
include { MINIMAP2_ALIGN as MINIMAP2_POLISH3 } from '../../../modules/nf-core/minimap2/align/main.nf'
include { RACON as RACON1 }                    from '../../../modules/nf-core/racon/main.nf'
include { RACON as RACON2 }                    from '../../../modules/nf-core/racon/main.nf'
include { RACON as RACON3 }                    from '../../../modules/nf-core/racon/main.nf'

workflow POLISH_RACON {
    take:
    ch_assembly   // channel: [ val(meta), path(assembly) ]
    ch_reads      // channel: [ val(meta), path(reads) ]

    main:
    // ---- Round 1 ----
    MINIMAP2_POLISH1(ch_reads, ch_assembly, false, [], false, false)
    ch_racon1 = ch_reads
        .join(ch_assembly)
        .join(MINIMAP2_POLISH1.out.paf)
        .map { meta, reads, assembly, paf -> [ meta, reads, assembly, paf ] }
    RACON1(ch_racon1)

    // ---- Round 2 ----
    MINIMAP2_POLISH2(ch_reads, RACON1.out.improved_assembly, false, [], false, false)
    ch_racon2 = ch_reads
        .join(RACON1.out.improved_assembly)
        .join(MINIMAP2_POLISH2.out.paf)
        .map { meta, reads, assembly, paf -> [ meta, reads, assembly, paf ] }
    RACON2(ch_racon2)

    // ---- Round 3 ----
    MINIMAP2_POLISH3(ch_reads, RACON2.out.improved_assembly, false, [], false, false)
    ch_racon3 = ch_reads
        .join(RACON2.out.improved_assembly)
        .join(MINIMAP2_POLISH3.out.paf)
        .map { meta, reads, assembly, paf -> [ meta, reads, assembly, paf ] }
    RACON3(ch_racon3)

    emit:
    polished = RACON3.out.improved_assembly   // channel: [ val(meta), path(fasta.gz) ]
}

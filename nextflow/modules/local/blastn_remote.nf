process BLASTN_REMOTE {
    tag "${meta.id}"
    label 'process_low'

    // Requires outbound network access on the executing node (queries NCBI over the internet).
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0c/0c86cbb145786bf5c24ea7fb13448da5f7d5cd124fd4403c1da5bc8fc60c2588/data' :
        'community.wave.seqera.io/library/blast:2.17.0--d4fb881691596759' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*.blast.txt"), emit: txt

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def db       = params.blast_db ?: 'nt'
    def max_hits = params.blast_max_target_seqs ?: 10
    def outfmt   = params.blast_outfmt ?: '6 qseqid sseqid pident length mismatch gapopen evalue bitscore stitle'
    """
    # blastn cannot read gzipped queries directly; decompress if needed.
        case "${assembly}" in
        *.gz) gzip -dc ${assembly} > query.fasta ;;
        *)    cp ${assembly} query.fasta ;;
    esac

    blastn \\
        -query query.fasta \\
        -db ${db} \\
        -remote \\
        -out ${prefix}.blast.txt \\
        -outfmt "${outfmt}" \\
        -max_target_seqs ${max_hits}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.blast.txt
    """
}

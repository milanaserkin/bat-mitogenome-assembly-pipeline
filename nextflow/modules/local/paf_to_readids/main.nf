process PAF_TO_READIDS {
    tag "${meta.id}"
    label 'process_single'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
        'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(paf)

    output:
    tuple val(meta), path("*.readids.lst"), emit: readids

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def min_aln = params.min_alignment_length ?: 500
    """
    # Keep read IDs whose alignment length (qend - qstart) exceeds the threshold.
    # PAF columns: 1=qname 3=qstart 4=qend
    awk -F'\\t' '(\$4 - \$3) > ${min_aln} { print \$1 }' ${paf} \\
        | sort \\
        | uniq \\
        > ${prefix}.readids.lst
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.readids.lst
    """
}

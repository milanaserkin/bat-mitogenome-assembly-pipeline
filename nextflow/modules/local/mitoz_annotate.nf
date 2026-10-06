process MITOZ_ANNOTATE {
    tag "${meta.id}"
    label 'process_high'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mitoz:3.6--pyhdfd78af_1' :
        'quay.io/biocontainers/mitoz:3.6--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_mitoz"),        emit: results
    tuple val(meta), path("**/*.gbf"), optional: true, emit: gbf
    tuple val(meta), path("**/*.gff"), optional: true, emit: gff
    tuple val(meta), path("**/*summary*.txt"), optional: true, emit: summary

    when:
    task.ext.when == null || task.ext.when

    script:
    def args         = task.ext.args ?: ''
    def prefix       = task.ext.prefix ?: "${meta.id}"
    def clade        = params.mitoz_clade ?: 'Chordata'
    def genetic_code = params.mitoz_genetic_code ?: 2
    def mark_circ    = (params.mitoz_mark_circular == null || params.mitoz_mark_circular) ? true : false
    """
    # MitoZ wants an uncompressed FASTA. Optionally tag the contig as circular,
    # mirroring the original workflow.
    gzip -dc ${assembly} > input.fasta
    if [ "${mark_circ}" = "true" ]; then
        sed -i 's/^>/>circular /' input.fasta
    fi

    mitoz annotate \\
        --fastafiles input.fasta \\
        --outprefix ${prefix} \\
        --workdir ${prefix}_mitoz \\
        --thread_number ${task.cpus} \\
        --clade ${clade} \\
        --genetic_code ${genetic_code} \\
        ${args}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_mitoz
    touch ${prefix}_mitoz/${prefix}.gbf
    touch ${prefix}_mitoz/${prefix}.gff
    touch ${prefix}_mitoz/${prefix}.summary.txt
    """
}

process ASSEMBLY_METRICS {
    tag "${meta.id}"
    label 'process_single'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4f/4fe272ab9a519cf418160471a485b5ef50ea3f571a8e4555a826f70a4d8243ae/data' :
        'community.wave.seqera.io/library/seqkit:2.13.0--05c0a96bf9fb2751' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*.assembly_metrics.txt"), emit: metrics

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    out="${prefix}.assembly_metrics.txt"

    echo "== assembly summary (length, N50, GC%) ==" > \$out
    seqkit stats -a -T ${assembly} >> \$out

    echo "" >> \$out
    echo "== per-contig GC content (%) ==" >> \$out
    seqkit fx2tab --name --gc ${assembly} >> \$out
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.assembly_metrics.txt
    """
}

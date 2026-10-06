process READ_QC {
    tag "${meta.id}"
    label 'process_single'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4f/4fe272ab9a519cf418160471a485b5ef50ea3f571a8e4555a826f70a4d8243ae/data' :
        'community.wave.seqera.io/library/seqkit:2.13.0--05c0a96bf9fb2751' }"

    input:
    tuple val(meta), path(raw), path(trimmed), path(clean)

    output:
    tuple val(meta), path("*.read_qc.txt"), emit: qc

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def min_len  = params.qc_short_read_length ?: 200
    // Nanopore ligation-kit adapter probes (as used in the original QC checks)
    def adapter1 = params.qc_adapter1 ?: 'AAGCAGTGGTATCAACGCAGAGTAC'
    def adapter2 = params.qc_adapter2 ?: 'TTTCTGTTGGTGCTGATATTGCTG'
    """
    out="${prefix}.read_qc.txt"

    echo "== seqkit stats (raw -> trimmed -> cleaned) ==" > \$out
    seqkit stats -a -T ${raw} ${trimmed} ${clean} >> \$out

    echo "" >> \$out
    echo "== leftover adapter matches in cleaned reads ==" >> \$out
    echo -n "${adapter1}: " >> \$out
    ( zcat -f ${clean} | grep -c "${adapter1}" || true ) >> \$out
    echo -n "${adapter2}: " >> \$out
    ( zcat -f ${clean} | grep -c "${adapter2}" || true ) >> \$out

    echo "" >> \$out
    echo "== reads shorter than ${min_len} bp remaining in cleaned set ==" >> \$out
    seqkit seq -M ${min_len} ${clean} | ( grep -c "^@" || true ) >> \$out
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.read_qc.txt
    """
}

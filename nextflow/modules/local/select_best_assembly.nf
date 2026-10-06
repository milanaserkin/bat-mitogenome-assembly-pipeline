process SELECT_BEST_ASSEMBLY {
    tag "${meta.id}"
    label 'process_single'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
        'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(assemblies), path(infos)

    output:
    tuple val(meta), path("*.best.fasta"), emit: fasta
    tuple val(meta), path("*.selection.tsv"), emit: report

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def target = params.genome_size ?: 17000
    """
    report="${prefix}.selection.tsv"
    printf "assembly\\tcontigs\\ttotal_length\\tcircular\\tabs_diff\\n" > \$report

    best=""
    best_stem=""
    best_diff=999999999
    best_circ_ok=1   # 1 == false, prefer 0 (a 1-contig circular hit)

    for info in *.assembly_info.txt; do
        [ -e "\$info" ] || continue
        stem=\$(basename "\$info" .assembly_info.txt)
        contigs=\$(awk 'NR>1{c++} END{print c+0}' "\$info")
        totlen=\$(awk 'NR>1{s+=\$2} END{print s+0}' "\$info")
        circ=\$(awk 'NR>1 && toupper(\$4)=="Y"{f=1} END{print (f==1)?"TRUE":"FALSE"}' "\$info")
        diff=\$(( totlen - ${target} )); diff=\${diff#-}

        printf "%s\\t%s\\t%s\\t%s\\t%s\\n" "\$stem" "\$contigs" "\$totlen" "\$circ" "\$diff" >> \$report

        # Rank: a single-contig circular assembly always beats a non-circular one;
        # within the same circular status, pick the length closest to the target.
        circ_ok=1
        if [ "\$contigs" = "1" ] && [ "\$circ" = "TRUE" ]; then circ_ok=0; fi

        if [ "\$circ_ok" -lt "\$best_circ_ok" ] || { [ "\$circ_ok" -eq "\$best_circ_ok" ] && [ "\$diff" -lt "\$best_diff" ]; }; then
            best_circ_ok=\$circ_ok
            best_diff=\$diff
            best_stem=\$stem
        fi
    done

    if [ -z "\$best_stem" ]; then
        echo "ERROR: no Flye assemblies found for ${prefix}" >&2
        exit 1
    fi

    echo "# selected: \$best_stem (circular_single_contig=\$([ \$best_circ_ok -eq 0 ] && echo yes || echo no), abs_diff_to_${target}bp=\$best_diff)" >> \$report

    gzip -dc "\${best_stem}.assembly.fasta.gz" > "${prefix}.best.fasta"
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.best.fasta
    touch ${prefix}.selection.tsv
    """
}

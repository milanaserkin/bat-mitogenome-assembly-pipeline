/*
 * Adapter Trimming with Porechop
 */
process porechop {

    input:
    path input_reads

    output:
    path "${input_reads}_trimmed", emit: fastq
    path "qc_porechop_stats.txt", emit: qc

    script:
    """
   # 1. Run Porechop
    ~/Porechop/porechop-runner.py \\
        -i ${input_reads} \\
        -o ${input_reads}_trimmed.fastq \\
        --threads 16 \\
        --check_reads 50000 \\
        --adapter_threshold 85 \\
        --end_size 200 \\
        --min_split_read_size 200

    # 2. Run QC
    module load seqkit
    
    seqkit stat ${input_reads} ${input_reads}_trimmed.fastq > qc_porechop_stats.txt
    
    echo "\\nRaw read count:" >> qc_porechop_stats.txt
    grep -c "^@" ${input_reads} >> qc_porechop_stats.txt
    
    echo "Trimmed read count:" >> qc_porechop_stats.txt
    grep -c "^@" ${input_reads}_trimmed.fastq >> qc_porechop_stats.txt
    
    echo "Leftover Adapter 1:" >> qc_porechop_stats.txt
    grep -c "AAGCAGTGGTATCAACGCAGAGTAC" ${input_reads}_trimmed.fastq >> qc_porechop_stats.txt
    
    echo "Leftover Adapter 2:" >> qc_porechop_stats.txt
    grep -c "TTTCTGTTGGTGCTGATATTGCTG" ${input_reads}_trimmed.fastq >> qc_porechop_stats.txt
    
    """
}

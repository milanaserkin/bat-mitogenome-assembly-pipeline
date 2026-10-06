/*
 * Quality Filtering with fastplong
 */
process fastplong {

    input:
    path input_reads
    path trimmed_reads

    output:
    path "${trimmed_reads}_clean", emit: fastq
    path "qc_fastplong_stats.txt", emit: qc

    script:
    """
    # 1. Run Fastplong
    /users/mserkin/fastplong/fastplong.bin \\
        -i ${trimmed_reads} \\
        -o ${trimmed_reads}_clean.fastq \\
        -l 600 \\
        -q 12 \\
        -t 16 \\
        -s TGGTTCAGTT 

    # 2. Run QC
    module load seqkit
    
    seqkit stat ${input_reads} ${trimmed_reads} ${trimmed_reads}_clean.fastq > qc_fastplong_stats.txt
    
    echo "\\nTrimmed reads:" >> qc_fastplong_stats.txt
    grep -c "^@" ${trimmed_reads} >> qc_fastplong_stats.txt
    
    echo "Clean reads:" >> qc_fastplong_stats.txt
    grep -c "^@" ${trimmed_reads}_clean.fastq >> qc_fastplong_stats.txt

    echo "Reads under 200bp remaining:" >> qc_fastplong_stats.txt
    seqkit seq -m 200 ${trimmed_reads}_clean.fastq | grep -c "^@" >> qc_fastplong_stats.txt
    """
}
    
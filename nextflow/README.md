# bat-mitogenome

Nextflow (DSL2) port of a SLURM-based workflow that assembles a **bat mitochondrial
genome** from Oxford Nanopore reads and identifies the species by BLAST.

## Pipeline

```
raw FASTQ
  └─ Porechop            adapter trimming              → trimmed FASTQ
      └─ fastplong       quality/length filtering      → cleaned FASTQ (+ HTML/JSON QC)
          └─ minimap2    map to related mito reference → PAF
              └─ [awk]   keep reads w/ long alignments → read-ID list
                  └─ seqtk subseq  extract mito reads  → mito FASTQ
                      └─ Flye  min-overlap sweep (×N)  → N assemblies
                          └─ [select best]  1-contig / circular / ~genome_size → best FASTA
                              └─ Racon ×3  (minimap2→racon) → polished FASTA
                                  ├─ MitoZ   annotation      → GenBank / GFF / summary
                                  └─ blastn -remote (NCBI nt) → species hits (TXT)
```

QC reproduced from the original work: `seqkit stats` across raw→trimmed→cleaned,
leftover-adapter grep, short-read counts (`READ_QC`), fastplong HTML/JSON reports,
Flye selection table, and final assembly metrics incl. GC% (`ASSEMBLY_METRICS`).

## Inputs

A CSV samplesheet (`--input`):

```csv
sample,fastq,mito_reference
bat869,/path/00_rawReads_bat869.fastq,/path/MN125184.1_mito.fasta
```

## Usage

```bash
nextflow run . \
    --input assets/samplesheet.csv \
    --outdir results \
    -profile singularity      # or docker / conda / wave
```

Key parameters (see `nextflow.config` for all):

| Parameter | Default | Notes |
|-----------|---------|-------|
| `--genome_size` | `17000` | expected mitogenome size (bp) |
| `--flye_min_overlaps` | `[1000..2500]` | 12-value Flye sweep |
| `--min_alignment_length` | `500` | read-extraction PAF filter |
| `--porechop_args` | `--check_reads 50000 --adapter_threshold 85 ...` | from original SLURM |
| `--fastplong_args` | `-l 600 -q 12 -s TGGTTCAGTT` | from original SLURM |
| `--run_mitoz` | `true` | toggle MitoZ annotation |
| `--run_blast` | `true` | toggle remote BLAST |
| `--blast_db` | `nt` | queried remotely via `blastn -remote` |

## Notes

- **`blastn -remote`** queries NCBI over the internet — the executing node needs
  outbound network access, and NCBI rate-limits/times out large remote jobs.
- **MitoZ** uses the biocontainers image `mitoz:3.6`; if it misbehaves, disable it
  with `--run_mitoz false` and run annotation separately.
- The `test` profile (`-profile test`) uses tiny placeholder inputs for wiring
  validation only, not real results.
```

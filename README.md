# Bat Mitogenome Assembly Pipeline

**Project Overview**
This repository contains the workflow and scripts used to assemble a mitochondrial genome from raw Oxford Nanopore sequencing data. The goal of the project was to identify an unknown bat species from a spleen sample by analyzing its mitochondrial DNA.

### Technical Stack
* **Languages:** R, Bash
* **Sequencing Data:** Oxford Nanopore (long-read)
* **Tools:** Porechop, fastplong, Minimap2, Flye, Racon, MitoZ, BLAST
* **Infrastructure:** SLURM (High-Performance Computing cluster)

---

### Pipeline Workflow

<img width="835" height="417" alt="Screen Shot 2026-07-06 at 11 13 16 PM" src="https://github.com/user-attachments/assets/ddb363d2-07fb-416d-82a1-f9174c0e7441" />

**Steps:** Trimming -> Quality Filtering -> Mapping -> Assembly -> Polishing -> Annotation -> Identification

---

### Results

<img width="3000" height="3000" alt="circos" src="https://github.com/user-attachments/assets/34670975-481b-4480-85e3-8755641f6365" />

Starting with the raw Nanopore reads, adapters were trimmed, short/low-quality reads were filtered, and the mitogenome was assembled and polished. 

**Assembly Metrics**
* **Structure:** Circular
* **Length:** 16,696 bp
* **GC Content:** 41.84%
* **Annotation:** All 37 canonical mitochondrial genes detected

**Species Identification**
Based on the BLAST summary, *Rousettus aegyptiacus* had the highest number of hits (19). However, *Rousettus leschenaultii* had a higher mean identity score (98.50%), the highest bit score (26,284), and the longest maximum alignment (14,506 bp). These metrics provide strong evidence that the assembly belongs to *Rousettus leschenaultii*.

---

### Limitations and Future Improvements
Nanopore reads can be prone to NUMTs, repeats, and low coverage. These challenges were addressed through read mapping and polishing, though the pipeline was constrained by the specific tools available on the cluster environment. 

Future improvements to this pipeline could include:
* **Annotation:** Troubleshooting MitoZ to consistently mark circularity, or adding a secondary annotation tool to confirm outputs.
* **Polishing:** Running Medaka after Racon to further resolve homopolymer errors typical in Nanopore data.
* **Reproducibility:** Streamlining the individual bash scripts into an automated workflow manager (like Snakemake or Nextflow) to increase efficiency.

---

### Repository Structure

```text

├── scripts/
│   └── Serkin_bat_mito_project.Rmd    # RMarkdown file containing the pipeline workflow and analysis
├── figures/
│   ├── circos.jpg                                  # Circular visualization of the assembled mitogenome
│   ├── fastplong_QC_summary.png                    # Read quality control and trimming summary metrics
│   ├── median_qual_histogram.png                   # Sequencing read quality score distribution histogram
│   ├── mitochondrial_gene_annotation.png           # Functional mapping of the annotated mitochondrial genes
│   ├── mitochondrial_genome_assembly_metrics.png   # Length, coverage, and sequence metrics of the final assembly
│   ├── pipeline.png                                # Visual diagram of the complete assembly and analysis workflow
│   └── species_summary_BLAST.png                   # BLAST hit counts, bit scores, and identity percentages for species ID
├── Serkin_bat_mito_project.pdf        # Detailed project documentation and full report
└── README.md                          # Project overview and repository guide

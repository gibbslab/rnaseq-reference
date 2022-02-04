# **Rnaseq Pipeline From nf-core**

Rnaseq pipeline provides meaningful programs to analyse RNA sequencing data obtained from organisms with a reference genome and annotation. This analysis includes various steps including trimming of FASTQ files, contamination removal, alignment, counting, quality control and normalization of sequenced reads, and, in most cases, differential expression (DE) analysis across conditions. This pipeline is supported by [nf-core](https://nf-co.re/rnaseq)


## **1.  Trimming**
-	[cat](http://www.linfo.org/cat.html) Merge re-sequenced FastQ files
-	[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) Read QC
-	[UMI-tools](https://github.com/CGATOxford/UMI-tools) UMI extraction
-	[Trim galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) Adapter and quality trimming


## **2.  Contamination removal **

-	[BBSplit](http://seqanswers.com/forums/showthread.php?t=41288) Removal of genome contaminants
-	[SortMeRNA](https://github.com/biocore/sortmerna) Removal of ribosomal RNA


## **3.  Alignment and Quantification **

-	[STAR](https://github.com/alexdobin/STAR) using [Salmon](https://combine-lab.github.io/salmon/)
-	[STAR](https://github.com/alexdobin/STAR) via [RSEM](https://github.com/deweylab/RSEM)
-	[HiSAT2](https://daehwankimlab.github.io/hisat2/) NO QUANTIFICATION
-	[SAMtools](https://sourceforge.net/projects/samtools/files/samtools/) Sort and index alignments
-	[UMI-tools](https://github.com/CGATOxford/UMI-tools) UMI-based deduplication
-	[picard MarkDuplicates](https://broadinstitute.github.io/picard/)
-	[StringTie](https://ccb.jhu.edu/software/stringtie/) Transcript assembly and quantification
-	[bedGraphToBigWig](http://hgdownload.soe.ucsc.edu/admin/exe/) Create bigWig coverage files


## **4.  Quality Control and Normalization **

-	[RSeQC](http://rseqc.sourceforge.net/) An RNA-seq quality control package
-	[QualiMap](http://qualimap.conesalab.org/) Evaluating sequencing alignment data
-	[dupRadar](https://bioconductor.org/packages/release/bioc/html/dupRadar.html) A package for the assessment of PCR artifacts in RNA-Seq data
-	[Preseq](http://smithlabresearch.org/software/preseq/) A package for predicting and estimating the complexity of a genomic sequencing library


## **5.  Differential Expression Analysis **

-	[DEseq2](https://bioconductor.org/packages/release/bioc/html/DESeq2.html) A package for estimating differential gene expression based on the negative binomial distribution


## **6.  Sum up **

-	[MultiQC](https://multiqc.info/) Present QC for raw read, alignment, gene biotype, sample similarity, and strand-specificity checks



## **Instalation**

Rnaseq is built using Nextflow, a workflow tool to run tasks across multiple compute infrastructures and it also uses Docker/Singularity containers making installation trivial and results highly reproducible. This guide covers the installation and configuration for Ubuntu.


### **Nextflow**

a. Make sure that Java v8+ is installed

```
java -version
```

b. Install Nextflow

```
curl -fsSL get.nextflow.io | bash
```

c. Move the file to a directory accessible by your `$PATH` variable

```
sudo mv nextflow /usr/local/bin/
```

### **Docker**

For more information, visit [Docker website](https://docs.docker.com/)

a. Update the apt package index, and install the latest version of Docker Engine

```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

b. List the versions available in your repo

```
apt-cache madison docker-ce
```

c. Install a specific version

```
sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io
```

d. Verify that Docker is installed correctly by running the hello-world image

```
sudo docker run hello-world
```

e. Enable Docker permissions

```
sudo chmod 666 /var/run/docker.sock
```


### **nf-core**

a. Install nf-core tools

```
sudo pip3 install nf-core
```

b. List all nf-core pipelines and show available updates

```
nf-core list
```


## ** Reference Genome Options **

One of the first choice for retrieving the most common reference genomes of diverse organisms is by means of `AWS iGenomes`, stored in AWS S3. To obtain human genome as well as its annotation, this repository contains a script `aws-igenomes.sh` that can synchronize AWS-iGenomes and download these files

```
curl -fsSL https://ewels.github.io/AWS-iGenomes/aws-igenomes.sh > aws-igenomes.sh
```


## **Usage**

To perform an RNA-seq data analysis, the script `scr/rnaseq.sh` was implemented to systematically prepare, validate, and generate the results of pipeline

```
bash rnaseq.sh -c ~/Astrocyte.csv -r ~/references/Homo_sapiens/Ensembl/GRCh38/Sequence/WholeGenomeFasta/genome.fa -a ~/references/Homo_sapiens/Ensembl/GRCh38/Annotation/Genes/genes.gtf.gz -s unstranded -b star_rsem -p 30 -m 230 -x n -l ~/Astrocyte/SRA_Astrocyte/results/fastq/ -d ~/Astrocyte/rRNA_database/rRNA-paths.txt
```


## **Arguments**


### **Mandatory**


-	`-r:` Reference genome

-	`-a:` GTF annotation file

-	`-b:` Specifies the alignment algorithm to use. Available options are: `star_salmon`, `star_rsem` and `hisat2`


### **Optional**


-	`-c:` Samplesheet file containing information about the samples in the experiment. If this is provided, the `-n` option is not needed, otherwise it is recommended to create the file. An example is available in `data`

-	`-n:`  Sample name to be included in the first column of samplesheet file

-	`-x: ` This execution is a resume of a previous run or it is a new run. The options are: `y` or `n`

-	`-s:` Strandness of the library. Available options are: `unstranded`, `forward` and `reverse`

-	`-e:` Specifies the pseudo aligner to use. Available option is: `salmon`

-	`-d:` Text file containing paths to fasta files (one per line) that will be used to create the database for SortMeRNA. An example is available in `data`

-	`-i:` Create or not a new Genome index. If not specified, it will be created based on the type of aligner supplied

-	`-p:` CPUs

-	`-m:` Max memory to be used



## **Running in the background**


The Nextflow `-bg` flag launches Nextflow in the background or alternatively, you can use `screen/tmux` or similar tool to create a detached session which you can log back into at a later time



## **Result**

The script will create a local directory based on the libraries name. Within this directory, the following will be found

-	`result:` Contains the results of RNA-seq analysis

-	`work:` Contains the main pipeline workflows

-	`2022-01-31_15:46:17.COMMAND:` Contains the commands used for the actual launch. File name contains the date (%y%m%d) and the time (%H%M%S) when the command was last run. Thus, if it is resumed, it will be overwritten



## **Bug Reports**

Please report bugs through the GitHub issues system

# **Rnaseq Pipeline From nf-core**

Rnaseq pipeline provides meaningful programs to analyse RNA sequencing data obtained from organisms with a reference genome and annotation. This analysis includes various steps including trimming of FASTQ files, contamination removal, alignment, counting, quality control and normalization of sequenced reads, and, in most cases, differential expression (DE) analysis across conditions. This pipeline is supported by [nf-core](https://nf-co.re/rnaseq)


## **1.  Trimming**
-	[cat](http://www.linfo.org/cat.html) Merge re-sequenced FastQ files
-	[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) Read QC
-	[UMI-tools](https://github.com/CGATOxford/UMI-tools) UMI extraction
-	[Trim galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) Adapter and quality trimming


## **2.  Contamination Removal**

-	[BBSplit](http://seqanswers.com/forums/showthread.php?t=41288) Removal of genome contaminants
-	[SortMeRNA](https://github.com/biocore/sortmerna) Removal of ribosomal RNA


## **3.  Alignment and Quantification**

-	[STAR](https://github.com/alexdobin/STAR) using [Salmon](https://combine-lab.github.io/salmon/)
-	[STAR](https://github.com/alexdobin/STAR) via [RSEM](https://github.com/deweylab/RSEM)
-	[HiSAT2](https://daehwankimlab.github.io/hisat2/) NO QUANTIFICATION
-	[SAMtools](https://sourceforge.net/projects/samtools/files/samtools/) Sort and index alignments
-	[UMI-tools](https://github.com/CGATOxford/UMI-tools) UMI-based deduplication
-	[picard MarkDuplicates](https://broadinstitute.github.io/picard/) Duplicate read marking
-	[StringTie](https://ccb.jhu.edu/software/stringtie/) Transcript assembly and quantification
-	[bedGraphToBigWig](http://hgdownload.soe.ucsc.edu/admin/exe/) Create bigWig coverage files


## **4.  Quality Control and Normalization**

-	[RSeQC](http://rseqc.sourceforge.net/) An RNA-seq quality control package
-	[QualiMap](http://qualimap.conesalab.org/) Evaluating sequencing alignment data
-	[dupRadar](https://bioconductor.org/packages/release/bioc/html/dupRadar.html) A package for the assessment of PCR artifacts in RNA-Seq data
-	[Preseq](http://smithlabresearch.org/software/preseq/) A package for predicting and estimating the complexity of a genomic sequencing library


## **5.  Differential Expression Analysis**

-	[DEseq2](https://bioconductor.org/packages/release/bioc/html/DESeq2.html) A package for estimating differential gene expression based on the negative binomial distribution


## **6.  Sum up**

-	[MultiQC](https://multiqc.info/) Present QC for raw read, alignment, gene biotype, sample similarity, and strand-specificity checks



## **Installation**

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



## **Generate Samplesheet Format**

There are two methods to create the samplesheet that is used as input to `rnaseq` pipeline:

1.    From `fetchngs` pipeline. It can be found as `samplesheet.csv`. Nevertheless, the absolute path of `fastq_1` and `fastq_2` columns must be modified so that the `rnaseq` pipeline can read the FastQC.

2.    An executable Python script called `fastq_dir_to_samplesheet.py` has been provided if you would like to auto-create an input samplesheet based on a directory containing FastQ files before you run the pipeline (requires Python 3 installed locally)

a.   Download python script

```
wget -L https://raw.githubusercontent.com/nf-core/rnaseq/master/bin/fastq_dir_to_samplesheet.py
```

b.   Use as follows

```
./fastq_dir_to_samplesheet.py <FASTQ_DIR> samplesheet.csv --strandedness reverse
```



## **Reference Genome Options**

One of the first choice for retrieving the most common reference genomes of diverse organisms is by means of `AWS iGenomes`, stored in AWS S3. To obtain human genome as well as its annotation, this repository contains a script `aws-igenomes.sh` that can synchronize AWS-iGenomes and download these files

```
curl -fsSL https://ewels.github.io/AWS-iGenomes/aws-igenomes.sh > aws-igenomes.sh
```



## **Path to genome indexes**

If you manually provide the genome indexes, it is important to keep in mind that they must be in the following path

```
<{output}>/genome/index/<{idx}>
```

where `output` is the folder name containing the results and `idx` the indexes such as `rsem`, `hisat2` and `salmon`



## **Usage**

To perform an RNA-seq data analysis, the script `scr/rnaseq.sh` was implemented to systematically prepare, validate, and generate the results of pipeline

```
bash rnaseq.sh -c file.csv -r genome.fa -a genes.gtf -b star_rsem -o results -d rRNA-paths.txt -p 30 -m 230 -x n
```


## **Arguments**


### **Mandatory**

-	`-c:` Samplesheet file containing information about the samples in the experiment. An example is available in `data`

-	`-r:` Reference genome (FASTA)

-	`-a:` Genome annotation (GTF)

-	`-b:` Specifies the alignment algorithm to use. Available options are: `star_salmon`, `star_rsem` or `hisat2`

-	`-o:` The output directory where the results will be saved


### **Optional**

-	`-d:` Text file containing paths to fasta files (one per line) that will be used to create the database for SortMeRNA. An example is available in `data`

-	`-e:` Specifies the pseudo aligner to use. Available option is: `salmon`

-	`-p:` CPUs

-	`-m:` Max memory to be used

-	`-x:` This execution is a resume of a previous run or it is a new run. The options are: `y` or `n`

- `-t:` A custom configuration file to be used in the pipeline. An example is shown in `data` folder

-	`-i:` Create or not a new Genome index. If not specified, it will be created based on the type of aligner supplied



## **Running in the background**

The Nextflow `-bg` flag launches Nextflow in the background or alternatively, you can use `screen/tmux` or similar tool to create a detached session which you can log back into at a later time



## **Result**

The script will create a local directory based on the given output name showing the following folders:

-	`output_name:` Contains the results of RNA-seq analysis

-	`work:` Contains the main pipeline workflows

-	`2022-01-31_15:46:17.COMMAND:` Contains the commands used for the actual launch. File name contains the date (%y%m%d) and the time (%H%M%S) when the command was last run. Thus, if it is resumed, it will be overwritten



## **Bug Reports**

Please report bugs through the GitHub issues system

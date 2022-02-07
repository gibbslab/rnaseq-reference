#!/bin/bash

# ---------------------------------------------------------------------
# version: 1.0
# This script calls the nf-core/rnaseq pipeline as implemented at GiBBS
# Institute for Genetics - National University of Colombia

# Coding was implemented according to the BASH best practices here:
# https://bertvv.github.io/cheat-sheets/Bash.html
# ---------------------------------------------------------------------



# ---------------------------------------------------------------------
# FUNCTIONS
# ---------------------------------------------------------------------

# Checks if a file or directory exists.
# Receives 2 arguments. $1:Path to target and $2:type: dir(d) or file(f))

function exists (){	

local target="${1}"
local type="${2}"

if [[ "${type}" == "f" ]];then

	if [ -f "${target}" ];then
		return 1
	else
		return 0
	fi

elif [[ "${type}" == "d" ]];then

	if [ -d "${target}" ];then
		return 1
	else
		return 0
	fi

else
	echo "Missing or wrong parameter in calling function exists()"
	exit 1
fi

}


# ---------------------------------------------------------------------
# The following parameters should be provided:
# 1) A CSV file containing the experimental design
# 2) Name of samples
# 3) Reference genome
# 4) GTF file
# 5) Strandedness of library. Option: 'unstranded/forward/reverse'
# 6) Aligner. Option: 'star_salmon/star_rsem/hisat2'
# 7) Pseudo-aligner. Option: 'salmon'
# 8) Optional (-x): Whether this run is a resume or a new job
# 9) CPUs
# 10) Max memory to be used
# 11) Path to libraries
# 12) Text file containing paths with fasta files to SortMeRNA database
# 13) Path to indices
# 14) Setting custom parameters
# ---------------------------------------------------------------------


while getopts c:n:r:a:s:b:e:x:p:m:l:d:i:t: flag
do
    case "${flag}" in
        c) csv=${OPTARG};;
        n) name=${OPTARG};;
        r) refGenome=${OPTARG};;
        a) annotFile=${OPTARG};;
        s) strand=${OPTARG};;
        b) align=${OPTARG};;
        e) pseuAlign=${OPTARG};;
        x) resume=${OPTARG};;
        p) cpu=${OPTARG};;
        m) memory=${OPTARG};;
        l) lib=${OPTARG};;
        d) rRNA=${OPTARG};;
        i) idx=${OPTARG};;
        t) config=${OPTARG};;
       \?) echo "Invalid option: $OPTARG" 1>&2;;
        :) echo "Invalid option: $OPTARG requires an argument" 1>&2;;
    esac
done

# if none parameter is passed:
if [ $# -eq 0 ]; then

    echo ""
    echo ""
    echo "   ---------------------------------------------------------"
    echo ""
    echo "            GiBBS references based RNAseq Anlysis             "
    echo "           Bioinformatics and Systems Biology Group           "
    echo "   Institute for Genetics - National University of Colombia   "
    echo "                  https://gibbslab.github.io/                 "
    echo ""
    echo "   ---------------------------------------------------------"
    echo ""
    echo " **Empty parameters! Unable to run**. Please provide the following parameters:"
    echo "
 	 -c: CSV file containing the experimental design
         -n: Provide name of samples
         -r: Reference genome
         -a: GTF file
         -s: 'Strandness' of the library. Option: 'unstranded/forward/reverse'
	 -b: Specifies the alignment algorithm to use. Option: 'star_salmon/star_rsem/hisat2'
         -e: Specifies the pseudo aligner to use. Option: 'salmon'
 	 -p: CPUs
         -m: Max memory to be used (ej. -m 100.GB) Please note the syntaxis
	 -x: Resume a previous Job. Options: y/n
         -l: Path to libraries directory
         -d: Text file containing paths to create the database for SortMeRNA. Options: {empty/TXT with paths}
	 -i: Create or not a new Genome index
         -t: Setting custom parameters
	    
	 "

    exit 1
fi

# ---------------------------------------------------------------------

#                   COMMAND LINE VALIDATION
# This section evaluates the input and performs a series of
# steps based on whether a given parameter is set or not.

# ---------------------------------------------------------------------

# Mandatory: Reference Genome
if [ -z "${refGenome}" ];then
	printf "Missing Reference Genome File. Please provide it and run again.\n"
	exit 1
else
	# Target is a file (f)
	t="f"
	exists ${refGenome} ${t}	
	# Check return value, can be 1 or 0
	if [ $? -eq 0 ];then
		printf "${refGenome} not found. Quitting.\n"
		exit 1	
	fi
	
	unset ${t}
fi


# Mandatory: GTF annotation file
if [ -z "${annotFile}" ];then
	printf "Missing GTF File. Please provide it and run again.\n"
	exit 1
else
	# Target is a file (f)
	t="f"
	exists ${annotFile} ${t}	
	# Check return value, can be 1 or 0
	if [ $? -eq 0 ];then
		printf "${annotFile} not found. Quitting.\n"
		exit 1	
	fi
	
	unset ${t}
fi


# Mandatory: Type of aligner
if [ -z "${align}" ];then
	printf "Missing Aligner Type. Please provide the alignment to use: star_salmon, star_rsem or hisat2.\n"
	exit 1
fi


# Mandatory: Path to libraries
if [ -z "${lib}" ];then
	printf "Missing Path to library. Please provide it and run again.\n"
	exit 1
else
	# Target is a Dir (d)
	t="d"
	exists ${lib} ${t}	
	# Check return value, can be 1 or 0
	if [ $? -eq 0 ];then
		printf "${lib} not found. Quitting.\n"
		exit 1	
	fi
	
	unset ${t}
fi


# Optional: CSV file
if [ -z "${csv}" ];then
	printf "CSV file not provided. A single CSV file will be created per library.\n"
        csv="new"
else
        # Target is a file (f)
        t="f"
        exists ${csv} ${t}
        # Check return value, can be 1 or 0
        printf "${csv} Using the CSV file by the user.\n"
        unset ${t}
fi


# Optional: Name of samples
if [ -z "${name}" ];then
	printf "Name not provided.\n"
        name="sample"
else
    printf "Name set to: ${name}.\n"
    
fi


# Optional: Type of Pseudo-aliggner
if [ -z "${pseuAlign}" ];then
	printf "Missing Pseudo_aligner Type. Please provide the pseudo-alignment to use: salmon.\n"
fi


# Optional: Strandeness
if [ -z "${strand}" ];then
	printf "Strandness set to default: Unstranded RNAseq.\n"
	    strand="unstranded"
else
    printf "Strandness set to: ${strand}.\n"
    
fi


# Optional: CPU
if [ -z "${cpu}" ];then
	cpu=$(cat /proc/cpuinfo | grep -c 'processor')
	printf "CPUs to use not provided. Using all $cpu cores available.\n"
fi


# Optional: Memory
if [ -z "${memory}" ];then
	memory=$(vmstat -s -S M | grep 'total memory' | awk '{ print $1 / (1024) }'  | awk '{ print int($1+0.5) }')
	printf "Max memory not provided. Using all $memory GB of memory.\n"
fi


# Optional: Resume previous Job
if [[ "$resume" == "y" ]];then
	printf "Resuming previous Job\n"
	again="-resume"
elif [[ "$resume" == "n" ]];then
	printf "Starting a new Job\n"
	again=" "
else
	printf "Missing option y/n for resuming process (-x option). Quitting.\n"
	exit 1
fi


# Optional: TXT with paths to rRNA databases
if [ -z "${rRNA}" ];then
	printf "Missing TXT File. Please provide it and run again.\n"
else
	# Target is a file (f)
	t="f"
	exists ${rRNA} ${t}	
	# Check return value, can be 1 or 0
	if [ $? -eq 0 ];then
		printf "${rRNA} not found. Quitting.\n"
		exit 1	
	fi
	
	unset ${t}
fi


# Optional: Custom config
if [ -z "${config}" ];then
	printf "No parameter options are supplied. You can create a local config file and use it.\n"
	config=0
else
	# Target is a file (f)
	t="f"
	exists ${config} ${t}	
	# Check return value, can be 1 or 0
	if [ $? -eq 0 ];then
		printf "${config} not found. Quitting.\n"
		exit 1	
	fi
	
	unset ${t}
fi


# Optional: Path to indeces depending on the aligner type
# NOTE: Both the STAR and RSEM indices should be present in the same path
if [ -z "${idx}" ];then
	printf "Path to Genome index not provided. We will create a new one based on aligner.\n"
        if [[ "${align}" == "star_salmon" ]] || [[ "${pseuAlign}" == "salmon" ]];then
            idx="salmon"

            elif [[ "${align}" == "star_rsem" ]];then
            idx="rsem"

            else [[ "${align}" == "hisat2" ]]
            idx="hisat2"
        fi
else
    if [[ "${align}" == "star_salmon" ]] || [[ "${pseuAlign}" == "salmon" ]];then
        printf "Checking path for salmon_index.\n"
        t="d"
        exists ${idx} ${t}	
        # Check return value, can be 1 or 0
        if [ $? -eq 0 ];then
    	printf "${idx} not found. Quitting.\n"
        exit 1
	else
        idx="salmon"
        fi
        printf "Using genome index: ${idx}\n"

    elif [[ "${align}" == "star_rsem" ]];then
        printf "Checking path for rsem_index.\n"
        t="d"
        exists ${idx} ${t}	
        # Check return value, can be 1 or 0
        if [ $? -eq 0 ];then
    	printf "${idx} not found. Quitting.\n"
        exit 1
	else
        idx="rsem"
        fi
        printf "Using genome index: ${idx}\n"

    else [[ "${align}" == "hisat2" ]]
        printf "Checking path for hisat2_index.\n"
        t="d"
        exists ${idx} ${t}	
        # Check return value, can be 1 or 0
        if [ $? -eq 0 ];then
    	printf "${idx} not found. Quitting.\n"
        exit 1
	else
        idx="hisat2"
        fi
        printf "Using genome index: ${idx}\n"
    fi
fi




# ---------------------------------------------------------------------
#                   ENVIRONMENT SETUP
# Create Directory and setup enviroment for running this Job
# ---------------------------------------------------------------------


# Get the name of  read
# ie. /datos/shared/usftp21.novogene.com/raw_data/CCC133/CCC133_1.fastq.gz 
read=$(ls ${lib}/*_1.fastq.gz)
	
# Get the read name without path and extension
#ie. CCC133
jobName=$(basename ${read%%_*})
        
#Create a working directory for this Job based on library name
mkdir -p ${jobName}
cd $jobName

#If CSV file was not provided, it was set to "0" above
if [[ "${csv}" == "new"  ]];then
    csv=${jobName}.csv

    #Here we make sure that CSV file is re-created.

    # header
    printf '%s,%s,%s,%s\n' sample fastq_1 fastq_2 strandedness > ${csv}
    
    #values
    for fastq_1 in ${read}
    do
    fastq_2="${fastq_1%_1.fastq.gz}_2.fastq.gz"

    [[ -f $fastq_2 ]] || continue # may display an error message

    printf '%s,%s,%s,%s\n' \
        "${name}" \
        "${fastq_1}" \
        "${fastq_2}" \
        "${strand}"
    done  >> ${csv}

fi

# ---------------------------------------------------------------------
#
# Let's prepare the command line
#
# ---------------------------------------------------------------------
command="nextflow run nf-core/rnaseq $again \
      --input $csv \
      --skip_bbsplit \
      --remove_ribo_rna \
      --ribo_database_manifest $rRNA \
      --save_non_ribo_reads \
      --fasta $refGenome \
      --gtf $annotFile \
      --save_reference \
      --save_trimmed \
      --aligner $align \
      --save_unaligned \
      --save_align_intermeds \
      --skip_markduplicates \
      --skip_stringtie \
      --skip_deseq2_qc \
      --max_cpus $cpu \
      --max_memory $memory.GB \
      -profile docker "
# If the user provide a pseudo-aligner, it will be set by default
# Append salmon as pseudo-aligner to command line

if [[ "${pseuAlign}" == "salmon" ]];then
    command="${command} --pseudo_aligner ${pseuAlign}"
fi

# If user does not provide indices, it should include the option to create and store them
# Append salmon_index to command line

link="./results/genome"

if [[ "${idx}" == "salmon" ]];then
    mkdir -p ${link}/${idx}
    path=$(printf "$(cd "$(dirname "${link}/${idx}")" && pwd)/$(basename "${link}/${idx}")")
    command="${command} --salmon_index ${path}"

# Append rsem_index to command line
elif [[ "${idx}" == "rsem" ]];then
    mkdir -p ${link}/${idx}
    path=$(printf "$(cd "$(dirname "${link}/${idx}")" && pwd)/$(basename "${link}/${idx}")")
    command="${command} --rsem_index ${path}"

# Append hisat2_index to command line
else [[ "${idx}" == "hisat2" ]]
    mkdir -p ${link}/${idx}
    path=$(printf "$(cd "$(dirname "${link}/${idx}")" && pwd)/$(basename "${link}/${idx}")")
    command="${command} --hisat2_index ${path}"
fi

# If the user provides custom settings, it is added to the pipeline

if [[ "${config}" != "0" ]];then
    command="${command} -c ${config}"
fi

printf "All set up. Running the following command: \n${command}\n"

# Starting time of process
start=$(date +%s)

# Create a file with the complete command line
timestamp=$(date "+%Y-%m-%d_%H:%M:%S")
printf "${command}" > ${timestamp}.COMMAND 

#-------------------------------------------
# RUN ME!!!!# RUN ME!!!!!!
#-------------------------------------------

$command

#-------------------------------------------
# POST RUN SET UP
#-------------------------------------------

# Elapsed time of execution process
end=$(date +%s)
printf "Elapsed Time: $(($end-$start)) seconds" > ${jobName}/time.tmp


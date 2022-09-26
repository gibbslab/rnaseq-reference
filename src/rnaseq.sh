#!/bin/bash

# ---------------------------------------------------------------------
# version: 2.0
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
#    Mandatory
# 1) A CSV file containing the experimental design
# 2) Reference genome (FASTA)
# 3) Genome annotation (GTF)
# 4) Aligner. Option: 'star_salmon/star_rsem/hisat2'
# 5) The output directory where the results will be saved
#    Optional
# 6) Text file containing paths with fasta files to SortMeRNA database
# 7) Pseudo-aligner. Option: 'salmon'
# 8) CPUs
# 9) Max memory to be used
# 10) (-x): Whether this run is a resume or a new job
# 11) Setting custom parameters
# 12) Path to indexes
# ---------------------------------------------------------------------



while getopts c:r:a:b:o:d:e:p:m:x:t:i: flag
do
    case "${flag}" in
        c) csv=${OPTARG};;
        r) refGenome=${OPTARG};;
        a) annotFile=${OPTARG};;
        b) align=${OPTARG};;
	o) output=${OPTARG};;
	d) rRNA=${OPTARG};;
        e) pseuAlign=${OPTARG};;
        p) cpu=${OPTARG};;
        m) memory=${OPTARG};;
        x) resume=${OPTARG};;
        t) config=${OPTARG};;
        i) idx=${OPTARG};;
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
             Mandatory
         -c: CSV file containing the experimental design
         -r: Reference genome (FASTA)
         -a: Genome annotation (GTF)
         -b: Specifies the alignment algorithm to use. Option: 'star_salmon/star_rsem/hisat2'
         -o: The output directory where the results will be saved
	     Optional
	 -d: Text file containing paths to create the database for SortMeRNA. Options: {empty/TXT with paths}
	 -e: Pseudo-aligner. Option: 'salmon'
         -p: CPUs
         -m: Max memory to be used (ej. -m 100.GB) Please note the syntaxis
         -x: Resume a previous Job. Options: y/n
         -t: Setting custom parameters
	 -i: Create or not a new Genome index
	    
	 "

    exit 1
fi

# ---------------------------------------------------------------------

#                   COMMAND LINE VALIDATION
# This section evaluates the input and performs a series of
# steps based on whether a given parameter is set or not.

# ---------------------------------------------------------------------

# Mandatory: CSV file
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


# Mandatory: Name of output directory
if [ -z "${output}" ];then
        printf "Output not provided.\n"
        output="RNA-seq"
else
    printf "Output set to: ${output}.\n"

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


# Optional: Type of Pseudo-aliggner
if [ -z "${pseuAlign}" ];then
	printf "Missing Pseudo_aligner Type. Please provide the pseudo-alignment to use: salmon.\n"
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


# Optional: Path to indexes depending on the aligner type
# NOTE: Both the STAR and RSEM indices should be present in the path: <<{output}>>/genome/index/<<{idx}>>
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
#
# Let's prepare the command line
#
# ---------------------------------------------------------------------
command="nextflow run nf-core/rnaseq $again \
      --input $csv \
      --outdir $output \
      --skip_bbsplit \
      --remove_ribo_rna \
      --ribo_database_manifest $rRNA \
      --save_non_ribo_reads \
      --fasta $refGenome \
      --gtf $annotFile \
      --gencode \
      --save_reference \
      --save_trimmed \
      --aligner $align \
      --save_unaligned \
      --save_align_intermeds \
      --skip_markduplicates \
      --skip_stringtie \
      --max_cpus $cpu \
      --max_memory $memory.GB \
      -profile docker "
      
      
# If the user provide a pseudo-aligner, it will be set by default
# Append salmon as pseudo-aligner to command line

if [[ "${pseuAlign}" == "salmon" ]];then
    command="${command} --pseudo_aligner ${pseuAlign}"
fi

# If user does not provide indexes, it should include the option to create and store them


link="${output}/genome/index"

if [ -z "${idx}" ];then
        printf "Indexes will be created.\n"
else

# Append salmon_index to command line
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
printf "Elapsed Time: $(($end-$start)) seconds" > ${outdir}/time.tmp


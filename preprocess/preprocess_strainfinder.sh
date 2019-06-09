#!/bin/bash

### input_folder: folder contains *pair-end* fastq files (*{1,2}.fastq.gz)

set -e -o pipefail
shopt -s nullglob

############ Input data #############
input_folder=$1                     #
#####################################

############ Scripts & data ##########################################
filter_script=~/scripts/StrainFinder/preprocess/1.filter_sam.py 
kpileup_script=~/scripts/StrainFinder/preprocess/3.kpileup.pl
ref=~/data/strainfinder_wd/all.amphora_genes.fst
gene_file=~/data/strainfinder_wd/gene_file.txt
######################################################################

########### Parameters ##############################
proc=8 ## number of processors used for BWA

####################################################

iter=`find -L $input_filder -name "*1.fastq.gz"`

for i in $iter;
do
    prefix=`basename $i | sed 's/.1.fastq.gz//'`
    input1=$i
    input2=${i/1.fastq.gz/2.fastq.gz}

    echo "============= StrainFinder preprocessing script ============"
    echo Output prefix: $prefix
    echo Fastq1: $input1
    echo Fastq2: $input2

    echo "======== alignment ========="
    zcat $input1 $input2 | \
	bwa mem -Y -v 1 -t $proc -a $ref - | \
	python2 $filter_script - 90 40 | \
	/usr/bin/samtools view -buS -F4 - | \
	/usr/bin/samtools sort - ${prefix}.sorted 
    echo "======== pileup =========="
    perl $kpileup_script $prefix ${prefix}.sorted.bam ${gene_file} 20 0 10 > ${prefix}.kp.txt
done

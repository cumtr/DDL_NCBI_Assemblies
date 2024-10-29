#!/bin/bash

set -e

#######################################################################

# This script requires the installation of NCBI Dataset CLI tools :
# conda install -c conda-forge ncbi-datasets-cli

########################################################################

# Initialize variables
genus=""
outFile=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -g|--Genus)
            genus="$2"
            shift # past argument
            shift # past value
            ;;
        -o|--OutFile)
            outFile="$2"
            shift # past argument
            shift # past value
            ;;
        *)  # unknown option
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if both arguments are provided
if [ -z "$genus" ] || [ -z "$outFile" ]; then
  echo "Usage: $(basename "$0") -g <Genus> -o <OutFile>"
  exit 1
fi

# Output the arguments
echo "Genus: $genus"
echo "OutFile: $outFile"

# 
datasets summary genome taxon $genus --assembly-source genbank --as-json-lines | \
dataformat tsv genome --fields organism-name,assminfo-biosample-accession,accession,assminfo-name,organism-infraspecific-breed,assminfo-sequencing-tech,assmstats-genome-coverage,assmstats-total-sequence-len,checkm-completeness,assmstats-scaffold-l50,assmstats-scaffold-n50,assmstats-contig-l50,assmstats-contig-n50 > ${outFile}

awk -F "\t" 'NR>2 {print $2}'  ${outFile} > ${outFile%.txt}.csv


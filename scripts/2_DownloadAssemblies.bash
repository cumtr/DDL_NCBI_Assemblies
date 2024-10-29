#!/bin/bash

set -e

# Initialize variables
assembly=""
Outfile=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -o|--Outfile)
            Outfile="$2"
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
if [ -z "$Outfile" ]; then
  echo "Usage: $(basename "$0") -o <Outfile>"
  exit 1
fi

# Output the arguments
assembly=`basename -s .fasta.gz $Outfile`
echo "Processing Assembly: $assembly"

###
# Download the zipped assembly folder from NCBI using curl
curl -OJX GET "https://api.ncbi.nlm.nih.gov/datasets/v1/genome/accession/${assembly}/download?filename=${assembly}.zip" -H "Accept: application/zip"

###
# Unzip the downloaded file and remove the original zip file
mkdir -p data/Assemblies/${assembly}/
unzip -o ${assembly}.zip -d data/Assemblies/${assembly}/ 
rm ${assembly}.zip
touch data/Assemblies/${assembly}/${assembly}.done

###
# Extract relevant information from the JSONL sequence report using jq
# Then filter out unplaced contigs, replace contig names with chromosomes,
# and convert to single line fasta format using awk and seqtk
# Finally, compress the result into bgzf format using bgzip
#echo "Curation of the fasta file for : $assembly" 

# jq -j '.genbankAccession, " ",.chrName, "\n"' data/Assemblies/${assembly}/ncbi_dataset/data/${assembly}/sequence_report.jsonl |\
#   grep -v "Un$" |\
#   awk 'NR==FNR{a[">"$1]=">"$2;next} {if ($1~/>/) {if ($1 in a) {print a[$1]} else {print $1}} else {print $0}}' - data/Assemblies/${assembly}/ncbi_dataset/data/${assembly}/${assembly}*.fna |\
#   seqtk seq |\
#   bgzip -@ 2 -c > data/Assemblies/${assembly}/${assembly}.fasta.gz

cat data/Assemblies/${assembly}/ncbi_dataset/data/${assembly}/${assembly}*.fna | bgzip -@ 2 -c > data/Assemblies/${assembly}/${assembly}.fasta.gz
# Index the compressed assembly using samtools faidx
samtools faidx data/Assemblies/${assembly}/${assembly}.fasta.gz

# clean the directory
rm -rf data/Assemblies/${assembly}/ncbi_dataset/
rm data/Assemblies/${assembly}/README.md
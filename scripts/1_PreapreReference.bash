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

assembly=`basename -s _renamed.fasta.gz $Outfile`
echo "Processing Assembly: $assembly"

curl -OJX GET "https://api.ncbi.nlm.nih.gov/datasets/v1/genome/accession/${assembly}/download?filename=${assembly}.zip" -H "Accept: application/zip"

###
# Unzip the downloaded file and remove the original zip file
mkdir -p data/REFERENCE/${assembly}/
unzip -o ${assembly}.zip -d data/REFERENCE/${assembly}/ 
rm ${assembly}.zip

jq -j '.genbankAccession, " ",.chrName, "\n"' data/REFERENCE/${assembly}/ncbi_dataset/data/${assembly}/sequence_report.jsonl |\
   grep -v "Un$" |\
   awk 'NR==FNR{a[">"$1]=">"$2;next} {if ($1~/>/) {if ($1 in a) {print a[$1]} else {print $1}} else {print $0}}' - data/REFERENCE/${assembly}/ncbi_dataset/data/${assembly}/${assembly}*.fna |\
   seqtk seq |\
   bgzip -@ 2 -c > data/REFERENCE/${assembly}/${assembly}_renamed.fasta.gz




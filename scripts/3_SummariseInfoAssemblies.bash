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

echo "Species Assembly_Name TotalAssemblySize N/L50_NCBI N/L90_NCBI BUSCO_Single BUSCO_Duplicated BUSCO_FragmentedMissing BUSCO_FragementedMisplaced BUSCO_Missing Infos" > $$

for FILE in data/Assemblies/*; do
    Assembly=`basename $FILE`

    Description=`grep ${Assembly} data/ListAssembliesFromNCBI.txt | sed 's/ /_/g' | awk -F "\t" 'BEGIN {FS="\t";OFS="\t"} {print $1, $3, $8}'`
    
    N50_NCBI=`grep "Main genome scaffold N/L50" data/Assemblies/${Assembly}/bbmap_${Assembly}/${Assembly}.stats.txt | awk '{print $NF}'`
    N90_NCBI=`grep "Main genome scaffold N/L90" data/Assemblies/${Assembly}/bbmap_${Assembly}/${Assembly}.stats.txt | awk '{print $NF}'`

    Comple_S=`grep "S:" data/Assemblies/${Assembly}/compleasm_${Assembly}/summary.txt | awk '{print $1}' | sed 's/S://g' | sed 's/%,//g'`
    Comple_D=`grep "D:" data/Assemblies/${Assembly}/compleasm_${Assembly}/summary.txt | awk '{print $1}' | sed 's/D://g' | sed 's/%,//g'`
    Comple_F=`grep "F:" data/Assemblies/${Assembly}/compleasm_${Assembly}/summary.txt | awk '{print $1}' | sed 's/F://g' | sed 's/%,//g'`
    Comple_I=`grep "I:" data/Assemblies/${Assembly}/compleasm_${Assembly}/summary.txt | awk '{print $1}' | sed 's/I://g' | sed 's/%,//g'`
    Comple_M=`grep "M:" data/Assemblies/${Assembly}/compleasm_${Assembly}/summary.txt | awk '{print $1}' | sed 's/M://g' | sed 's/%,//g'`

    Infos=`grep ${Assembly} data/ListAssembliesFromNCBI.txt | sed 's/ /_/g' | awk -F "\t" 'BEGIN {FS="\t";OFS="\t"} {print $4"/"$5"/"$7}'`

    echo -e ${Description} ${N50_NCBI} ${N90_NCBI} ${Comple_S} ${Comple_D} ${Comple_F} ${Comple_I} ${Comple_M} ${Infos} >> $$
done

sed 's/ /\t/g' $$ > ${Outfile}
rm $$

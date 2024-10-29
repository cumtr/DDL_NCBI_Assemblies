# Download and Get Stats for Assemblies of a Given Taxon on the NCBI

This directory contains a Snakemake pipeline and companion scripts to download all assemblies from the NCBI for a given taxon and compute some basic statistics on those assemblies.

The stats include:
* Total Assembly Size 
* N and L50 (format: N/L50) 
* N and L90 (format: N/L90)
* BUSCO Single 
* BUSCO Duplicated 
* BUSCO FragmentedMissing 
* BUSCO FragmentedMisplaced 
* BUSCO Missing
* Additional information when available (e.g., Biosample name, sequencing technology used, total coverage)

##
## Preparation

### Extract the List of Assemblies for a Given Taxon on the NCBI

To query the NCBI, you will need the `ncbi_datasets` command-line tool.  
You can install it via:


```
# conda install -c conda-forge ncbi-datasets-cli
conda activate ncbi_datasets
```

To download the list of all assemblies for the *Ovis* genus, use:

```
mkdir -p data
bash ./scripts/0_MakeListAssemblies.bash -g ovis -o data/ListAssembliesFromNCBI.txt
```


This script creates a file named `data/ListAssembliesFromNCBI.txt` containing a list of all assemblies available on the NCBI for the specified taxon. If you do not wish to process certain assemblies, you can remove lines from this file before running the Snakemake pipeline.

### Prepare the Config File

To run the Snakemake pipeline, modify the config file to suit your settings. This file requires three pieces of information:

* **List of Assemblies** to download and process. This is the file produced above with the `./scripts/0_MakeListAssemblies.bash` script.
* **Database of Genes** for the BUSCO score. Specify only the name of the database you intend to use. For example, use `"agaricales"` to download `"agaricales_odb10.2024-01-08.tar.gz"`. The list of BUSCO databases is available [here](https://busco-data.ezlab.org/v5/data/lineages/).
* **ID of the Reference**. This is used in one of the rules to modify a copy of the sequences for this specific assembly (so that chromosome 1 is named `>1`, chromosome 2 `>2`, and so on).

A config file to use `GCA_002263795.4` as the reference for the *Ovis* genus and the `cetartiodactyla` dataset for the BUSCO score would look like:

```
ListAssemblies: "data/ListAssembliesFromNCBI.txt"
BUSCO_DB: "cetartiodactyla"
referenceID: "GCA_002263795.4"

```

##

## Run the Snakemake Pipeline

To run the Snakemake pipeline, ensure you have Snakemake installed and then run:

```
snakemake -s Snakefile --sdm conda --executor slurm --default-resources runtime=100h mem_mb_per_cpu=10G --jobs 10
```

This pipeline will install the necessary tools and run all the rules to extract the information for each assembly.

##

## Summarize all the informations

To summarize the information for all assemblies, use:

```
mkdir -p results
bash ./scripts/3_SummariseInfoAssemblies.bash -o results/StatsAssembliesFromNCBI.txt
```

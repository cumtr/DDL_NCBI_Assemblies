# import subprocess
configfile: "config.yaml"

def ListAssemblies():
     List_Assemblies = list()
     with open(config["ListAssemblies"], "r") as f:
          next(f)
          for line in f:
               temp = line.split("\t")
               List_Assemblies.append(temp[2])
          return List_Assemblies

Assemblies=ListAssemblies()
print(Assemblies)

import os 
directory = "data/Assemblies/"
if not os.path.exists(directory):
    os.makedirs(directory)


###########################################################


rule all:
        input:
                expand("data/Assemblies/{ASSEMBLY}/bbmap_{ASSEMBLY}/{ASSEMBLY}.stats.txt", ASSEMBLY=Assemblies),
                expand("data/Assemblies/{ASSEMBLY}/compleasm_{ASSEMBLY}/summary.txt", ASSEMBLY=Assemblies) # 'data/Assemblies/{Assembly}/compleasm_{Assembly}/summary.txt'

rule PrepareReference:
        output:
                expand("data/REFERENCE/{Ref}/{Ref}_renamed.fasta.gz", Ref=config["referenceID"])
        conda:
               "envs/tools.yaml"
        shell:
                '''
                bash scripts/1_PreapreReference.bash -o {output}
                '''

rule CreateAssembliesDirectory:
       output:
               "data/Assemblies/{Assembly}/{Assembly}.ready.txt" # expand("data/Assemblies/{Assembly}/{Assembly}.ready.txt", Assembly=Assemblies)
       conda:
               "envs/tools.yaml"
       shell:
               '''
               AssemblyName=`basename -s .ready.txt {output}`
               # create the directory structure
               mkdir -p data/Assemblies/$AssemblyName
               mkdir -p data/Assemblies/$AssemblyName/ncbi_AssemblyName
               # create the output file
               touch {output}
               '''

rule DownloadAndCurateAssemblies:
	input:
		"data/Assemblies/{Assembly}/{Assembly}.ready.txt" # expand("data/Assemblies/{Assembly}/{Assembly}.ready.txt", Assembly=Assemblies)
	output:
		"data/Assemblies/{Assembly}/{Assembly}.fasta.gz" # expand("data/Assemblies/{Assembly}/{Assembly}.fasta.gz", Assembly=Assemblies)
	conda:
		"envs/tools.yaml"
	shell:
		'''
		bash scripts/2_DownloadAssemblies.bash -o {output}
		'''

rule compleasm_download:
        output:
                "data/compleasm_db/"
        localrule: True
        shell:
                '''
                # ~/WORK/TOOLS/compleasm_kit/compleasm.py download {config[BUSCO_DB]} -L {output}
                compleasm download {config[BUSCO_DB]} -L {output}
                '''

rule compleasm_run:
        input:
                fasta = rules.DownloadAndCurateAssemblies.output #,
                #db = "/cluster/home/tcumer/WORK/REFERENCES/compleasm_db/cetartiodactyla_odb10.done"
        output:
                'data/Assemblies/{Assembly}/compleasm_{Assembly}/summary.txt'
        params:
                _dir = 'data/Assemblies/{Assembly}/compleasm_{Assembly}',
                _db = "/cluster/home/tcumer/WORK/REFERENCES/compleasm_db/"
        threads: 6
        resources:
                mem_mb = 25000
        conda:
                "envs/tools.yaml"
        shell:
                '''
                # release of compleasm : compleasm-0.2.6_x64-linux.tar.bz2
                compleasm run -a {input.fasta} -o {params._dir} -l {config[BUSCO_DB]} -L {params._db} -t {threads}
                # ~/WORK/TOOLS/compleasm_kit/compleasm.py run -a {input.fasta} -o {params._dir} -l {config[BUSCO_DB]} -L {params._db} -t {threads}
                '''

rule bbmap_run:
        input:
                fasta = rules.DownloadAndCurateAssemblies.output
        output:
                'data/Assemblies/{Assembly}/bbmap_{Assembly}/{Assembly}.stats.txt'
        params:
                _dir = 'data/Assemblies/{Assembly}/bbmap_{Assembly}',
                _FastaName = "data/Assemblies/{Assembly}/bbmap_{Assembly}/{Assembly}.fasta"
        conda:
                "envs/tools.yaml"
        shell:
                '''
                # copy and uncompress the fasta
                cp {input} {params._dir}
                gzip -d {params._FastaName}.gz
                # run bbmap
                stats.sh format=2 in={params._FastaName} out={output}
                # clean 
                rm {params._FastaName}
                '''

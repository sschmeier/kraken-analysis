#!/bin/bash
set -u

#######################################
#
# USAGE:
# sript.sh PREFIX FASTADIR KRAKENDB
#
if [ "$#" -ne 5 ]; then
    printf "USAGE: bash run-kraken-analysis.sh CONDAENV PREFIX FASTADIR KRAKENDB KRONATAX\n"
    printf "\n"
    printf "    CONDAENV: Name of conda env to source before running analysis.\n"
    printf "              Will be created if not exit. Assumes bioconda.\n"
    printf "    PREFIX  : Prefix for output directories.\n"
    printf "    FASTADIR: Path to directory with gzipped fasta-files to process.\n"
    printf "    KRAKENDB: Path to directory with kraken database.\n"
    printf "    KRONATAX: Path to directory with krona taxonomy.\n"
    printf "\n"
    exit
fi

# used for output directories prefix
PREFIX=$2
# path to dir with fasta-files, get the abs path
FASTADIR=$(readlink -f $3) 
# the path to the krakendb-dir, get the abs path
KRAKENDB=$(readlink -f $4)
KRONATAX=$(readlink -f $5)

SRC_DIR=$(pwd)
#######################################

# logfile name
logfile=$PREFIX-kraken-log.txt
printf "Logfile created: $logfile\n"
date > $logfile

# 0: Requirements 
# Load conda env with installed kraken-all, krona, numpy
# If env does not exit, create it.
#
ENV=$1
source activate $ENV
if [ $? -eq 0 ]; then
    :
else
    # Create the environment and activate
    printf "Conda env '$ENV' doesn't exist. Creating env.\n" >> $logfile
    conda create -n $ENV python=3 kraken-all krona numpy
    source activate $ENV
fi

printf "\nWORKINGDIR: $SRC_DIR\n" >> $logfile
printf "CONDAENV: $ENV\n"  >> $logfile
printf "PREFIX: $PREFIX\n"  >> $logfile
printf "FASTADIR: $FASTADIR\n"  >> $logfile
printf "KRAKENDB: $KRAKENDB\n\n"  >> $logfile
printf "KRONATAX: $KRONATAX\n\n"  >> $logfile

printf "## Writing conda requirements file.\n" >> $logfile
conda list -e > $PREFIX-conda-requirements.txt
printf "done\n\n" >> $logfile
#-----------------------------------------------    

# 1: set up result-dir structure
mkdir ./$PREFIX-kraken
mkdir ./$PREFIX-krona
#-----------------------------------------------    

# 2: we run kraken for each sample, e.g. 1 file per sample
printf "## Creating and executing kraken calls script:\n" >> $logfile
python create-kraken-calls.py $KRAKENDB $FASTADIR/ $PREFIX-kraken/ > $PREFIX-kraken-script.sh
bash $PREFIX-kraken-script.sh >> $logfile
printf "done\n\n" >> $logfile
#-----------------------------------------------    
        
# some classification stat
printf "## Kraken mapping stats\n" >> $logfile
for i in `find $PREFIX-kraken/*.err -print`; do 
    printf $i; cat $i | egrep -A1 classified;
done >> $logfile
printf "done\n\n" >> $logfile
#-----------------------------------------------    
    
# kraken translate
printf "## Creating kraken-translate files for:\n" >> $logfile
for fn in $PREFIX-kraken/*.kraken; do
    printf "$fn\n" >> $logfile;
    kraken-translate --db $KRAKENDB $fn | gzip > $fn.translate.gz;
done

printf "done\n\n" >> $logfile
#-----------------------------------------------    

# reports nonzero
printf "## Creating kraken-report files for:\n" >> $logfile
for fn in $PREFIX-kraken/*.kraken; do
    printf "$fn\n" >> $logfile;
    kraken-report --db $KRAKENDB $fn > $fn.report-nonzero.txt;
done

zip $PREFIX-kraken-reports-nonzero.zip $PREFIX-kraken/*.report-nonzero.txt
gzip $PREFIX-kraken/*.report-nonzero.txt
printf "done\n\n" >> $logfile 

## combine all reports into one
printf "## Combining kraken reports:\n" >> $logfile 
ls $PREFIX-kraken/*.kraken | head -1 | xargs -I pattern kraken-report --show-zeros --db $KRAKENDB pattern | cut -f 5,6 > $PREFIX-temp-alltax.txt
python combine-kraken-reports.py -o $PREFIX-kraken-reports-combined.txt.gz $PREFIX-temp-alltax.txt $PREFIX-kraken/*.report-nonzero.txt.gz
python combine-kraken-reports.py --scale -o $PREFIX-kraken-reports-combined-scaled.txt.gz $PREFIX-temp-alltax.txt $PREFIX-kraken/*.report-nonzero.txt.gz
printf "done\n\n" >> $logfile 

# create domain overview
printf "## Domain overview:\n" >> $logfile
python create-kraken-domainoverview.py $PREFIX-kraken/*.report-nonzero.txt.gz >> $logfile
printf "done\n\n" >> $logfile
#-----------------------------------------------    

# combined reports for all files
printf "## Create kraken-mpa-report file:\n" >> $logfile
kraken-mpa-report --header-line --db $KRAKENDB $PREFIX-kraken/*.kraken | gzip > $PREFIX-kraken-mpareport-combined.txt.gz
printf "done\n\n" >> $logfile
#-----------------------------------------------    

# 3: Visualise with krona
# copy used krona tax
mkdir ./$PREFIX-krona-tax
# test if korna taxonomy exists if not download
if [ ! -f $KRONATAX/taxonomy.tab ]; then
    printf "## Krona taxonomy not found. Downloading...\n" >> $logfile
    ktUpdateTaxonomy.sh ./$PREFIX-krona-tax
    KRONATAX=./$PREFIX-krona-tax
else
    printf "## Copy KRONA taxonomy for safekeeping into resultsdir.\n" >> $logfile
    cp $KRONATAX/taxonomy.tab ./$PREFIX-krona-tax/
fi

# Update krona taxonomy to use:
KRONATAX=./$PREFIX-krona-tax
printf "## KRONATAX PATH UPDATED: $KRONATAX\n"

printf "## Creating krona visualisations for:\n" >> $logfile
for fn in $PREFIX-kraken/*.kraken; do 
    printf "$fn\n" >> $logfile;
    cat $fn | cut -f 2,3 > $fn.kronainput;  
done
ktImportTaxonomy -tax $KRONATAX -o $PREFIX-krona/krona.html $PREFIX-kraken/*.kronainput >> $logfile;

zip -r $PREFIX-krona.zip $PREFIX-krona/ >> $logfile
printf "done\n\n" >> $logfile
#-----------------------------------------------    

# gzip kraken
printf "## Cleaning up:\n" >> $logfile 
gzip $PREFIX-kraken/*.kraken
gzip $PREFIX-kraken/*.err
rm $PREFIX-kraken/*.kronainput; 
rm $PREFIX-temp-alltax.txt
printf "done\n\n" >> $logfile

date >> $logfile
printf "FINISHED\n" >> $logfile
printf "FINISHED\n"

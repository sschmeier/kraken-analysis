# Kraken analysis

Analyse a bunch of fasta-files. 

```bash
$ bash run-kraken-analysis.sh
USAGE: bash run-kraken-analysis.sh CONDAENV PREFIX FASTADIR KRAKENDB KRONATAX

    CONDAENV: Name of conda env to source before running analysis.
              Will be created if not exit. Assumes bioconda.
    PREFIX  : Prefix for output directories and files.
    FASTADIR: Path to directory with gzipped fasta-files to process.
    KRAKENDB: Path to directory with kraken database.
    KRONATAX: Path to directory with krona taxonomy.
```

The script will try to source the [conda](http://conda.pydata.org/docs/intro.html) environment with installed dependencies from the [bioconda](https://bioconda.github.io) channel.

**Dependencies:**

- kraken-all
- krona
- numpy

If unsuccesful, the script will try to create a new conda environment and install the dependencies.

Add [bioconda](https://bioconda.github.io) channel with:

```bash
$ conda config --add channels conda-forge
$ conda config --add channels defaults
$ conda config --add channels r
$ conda config --add channels bioconda
```


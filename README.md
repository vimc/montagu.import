# montagu.import

Probably only useful for the 2018 import.  Bulk import of stochastic data.

Build the image

```
docker build -f docker/Dockerfile --tag vimc/montagu.import .
```

Save a file `env` with the contents:

```
MONTAGU_LOCATION=uat
MONTAGU_USERNAME=test.user@imperial.ac.uk
MONTAGU_PASSWORD=password
VAULT_ADDR='https://support.montagu.dide.ic.ac.uk:8200'
VAULT_AUTH_GITHUB_TOKEN=<token>
VAULTR_AUTH_METHOD=github
```

For production it would look like:

```
MONTAGU_LOCATION=production
MONTAGU_USERNAME=import.user@imperial.ac.uk
MONTAGU_PASSWORD=<password>
VAULT_ADDR='https://support.montagu.dide.ic.ac.uk:8200'
VAULT_AUTH_GITHUB_TOKEN=<token>
VAULTR_AUTH_METHOD=github
```

but the import user needs creating still.

A lot of files will cycle through the work directory so we need to mount that into the container too:

```
docker run -v ${PWD}:/import -w /import --user=$UID --env-file=env \
  vimc/montagu.import --help
```

To do a test import

```
docker run -t -v ${PWD}:/import -w /import --user=$UID --env-file=env \
  vimc/montagu.import --index 1 4
```

which will import the first file for the fourth entry in `dropbox_stochastic.csv`.  Omitting the `--index 1` will upload all files and using `--index 1..10` will upload 10 files.

To clear out an import

```
docker run -t -v ${PWD}:/import -w /import --user=$UID --env-file=env \
  vimc/montagu.import --clear 4
```

The `--lines=N` argument can be used to control the chunk size of the upload.  This changes how responsive things are and when errors will be thrown.

```
docker run -t -v ${PWD}:/import -w /import --user=$UID --env-file=env \
  vimc/montagu.import --index 1 --lines 50 4
```

## Doing the import from R

Create a file `.Renviron` containing

```
VAULT_ADDR='https://support.montagu.dide.ic.ac.uk:8200'
VAULT_AUTH_GITHUB_TOKEN=<your token>
VAULTR_AUTH_METHOD=github
```

See [the `vaultr` documentation](https://github.com/vimc/vaultr#usage) for more details.

### Installation

```
## install.packages(c("drat", "devtools")) # if needed
devtools::install_github("karthik/rdrop2", upgrade_dependencies = FALSE)
drat:::add("vimc")
install.packages(c("docopt", "montagu", "vaultr"))
devtools::install()
```

### Usage

Then should be able to run these lines:

montagu.import::dropbox_login()
```r
montagu.import::dropbox_login()
montagu.import::montagu_login("production")
```

Use `uat` for testing, but be aware that it probably can't handle a full import.  You can still try an import with `index = 1` to import just the first section of results.

To import the `i`th row of `dropbox_stochastic.csv` do:

```r
dat <- read_csv("dropbox_stochastic.csv")
montagu.import::stochastic_upload(as.list(dat[i, ]))
```

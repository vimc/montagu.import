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

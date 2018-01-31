## API docs:
## https://github.com/vimc/montagu-api/blob/master/docs/spec/BurdenEstimates.md

## Being developed at the same time as montagu-r so load that from
## local sources too:

devtools::load_all("../montagu-r")
devtools::load_all()

## All the auth:
dropbox_login()
montagu::montagu_set_default_location("uat")
montagu::montagu_authorise("test.user@imperial.ac.uk", "password")

## Our current set of files to upload:
dat <- read_csv("dropbox_stochastic.csv")
dat$dropbox <- sub("^/", "", dat$dropbox)

## Start with the first of these:
d <- as.list(dat[4, ])
montagu_burden_estimates(d$group, d$touchstone, d$scenario)

## First grab the certificate:
cert <- download_certificate(d)

## Then create a burden estimate set
id <- montagu_burden_estimate_set_create(d$group,
                                         d$touchstone,
                                         d$scenario,
                                         "stochastic",
                                         cert$id)

## Download the first estimate file:
## dropbox_index(unique(dat$dropbox), "dropbox")
filename <- download_estimate(d, 1L, "dropbox")

montagu_burden_estimate_set_upload(d$group,
                                   d$touchstone,
                                   d$scenario,
                                   id,
                                   filename,
                                   lines = 5000,
                                   keep_open = TRUE)

## Clean up
montagu_burden_estimate_set_clear(d$group,
                                  d$touchstone,
                                  d$scenario,
                                  id)

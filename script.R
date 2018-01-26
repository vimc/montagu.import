## We need the dropbox token
source("dropbox.R")
source("util.R")
dropbox_login()

devtools::load_all("~/Documents/Projects/epi/vimc/montagu-r")
montagu::montagu_set_default_location("uat")
montagu::montagu_authorise("test.user@imperial.ac.uk", "password")

dat <- read_csv("dropbox_stochastic.csv")
dat$dropbox <- sub("^/", "", dat$dropbox)

d <- as.list(dat[1, ])
montagu_burden_estimates(d$group, d$touchstone, d$scenario)


## First grab the certificate:
cert <- download_certificate(d)

path <- sprintf("File requests/%s", d$dropbox)
info <- rdrop2::drop_dir(path)

id <- montagu_burden_estimate_set_create(d$group,
                                         d$touchstone,
                                         d$scenario,
                                         "stochastic",
                                         cert$id)

filename <- download_estimate(d, 1L)

## This fails with 400:
## unknown-run-id: Unknown run ID with id '1'. Attempting to match against run parameter set null
montagu_burden_estimate_set_upload(d$group,
                                   d$touchstone,
                                   d$scenario,
                                   id,
                                   filename,
                                   TRUE)

## And this fails with 403:
## forbidden: You do not have sufficient permissions to access this resource. Missing these permissions: modelling-group:modelling_group_id/estimates.write
montagu_burden_estimate_set_clear(d$group,
                                  d$touchstone,
                                  d$scenario,
                                  id)

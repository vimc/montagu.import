## API docs:
## https://github.com/vimc/montagu-api/blob/master/docs/spec/BurdenEstimates.md

## Being developed at the same time as montagu-r so load that from
## local sources too:
devtools::load_all()

## All the auth:
dropbox_login()
montagu::montagu_set_default_location("uat")
montagu::montagu_authorise("test.user@imperial.ac.uk", "password")

## Our current set of files to upload:
dat <- read_csv("dropbox_stochastic.csv")
d <- as.list(dat[4, ])

stochastic_upload(d, index = 1L)

dat <- read_csv("dropbox_stochastic.csv")
d <- as.list(dat[4, ])
stochastic_upload(d)

montagu::montagu_burden_estimates(d$group, d$touchstone, d$scenario)

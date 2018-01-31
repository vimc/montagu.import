main_run <- function(clear, entry, index) {
  dat <- read_csv("dropbox_stochastic.csv")
  if (entry > nrow(dat)) {
    stop(sprintf("entry out of range [1, %d]", entry))
  }
  d <- as.list(dat[entry, ])
  if (clear) {
    stochastic_clear
  } else {
    stochastic_upload(d, index = index)
  }
}

main_args <- function(args = commandArgs(TRUE)) {
  'Usage:
   stochastic.import [options] <entry>

   Options:
   --index=INDEX   Optionally upload a single index (or a..b for a range)
   --keep-open     Keep the burden estimate set open
   --clear         Clear this entries incomplete uploads' -> usage
  oo <- options(warnPartialMatchArgs = FALSE)
  if (isTRUE(oo$warnPartialMatchArgs)) {
    on.exit(options(oo))
  }
  opts <- docopt::docopt(usage, args)
  names(opts) <- gsub("-", "_", names(opts))

  index <- opts$index
  if (!is.null(index)) {
    re_range <- "^([0-9]+)\\.\\.([0-9]+)$"
    if (grepl("^[0-9]+$", index)) {
      index <- as.integer(index)
    } else if (grepl(re_range, index)) {
      index <- seq(as.integer(sub(re_range, "\\1", index)),
                   as.integer(sub(re_range, "\\2", index)))
    } else {
      stop("Invalid input for index")
    }
  }

  list(clear = opts$clear,
       entry = as.integer(opts$entry),
       index = index)
}

main <- function(args = commandArgs(TRUE)) {
  args <- main_args(args)
  main_run(args$clear, args$entry, args$index)
}

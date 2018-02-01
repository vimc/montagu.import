main_run <- function(clear, entry, index, lines) {
  dat <- read_csv("dropbox_stochastic.csv")
  if (entry > nrow(dat)) {
    stop(sprintf("entry out of range [1, %d]", entry))
  }
  d <- as.list(dat[entry, ])

  auth_from_env()

  if (clear) {
    stochastic_clear
  } else {
    stochastic_upload(d, index = index, lines = lines)
  }
}

main_args <- function(args = commandArgs(TRUE)) {
  'Usage:
   stochastic.import [options] <entry>

   Options:
   --index=INDEX   Optionally upload a single index (or a..b for a range)
   --lines=N       Number of lines to upload in each request [default: 20000]
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

  if (is.null(opts$lines)) {
    lines <- 20000L
  } else {
    lines <- as.integer(opts$lines)
  }

  list(clear = opts$clear,
       entry = as.integer(opts$entry),
       lines = lines,
       index = index)
}

main <- function(args = commandArgs(TRUE)) {
  args <- main_args(args)
  main_run(args$clear, args$entry, args$index, args$lines)
  invisible()
}

auth_from_env <- function() {
  location <- Sys.getenv("MONTAGU_LOCATION", "")
  username <- Sys.getenv("MONTAGU_USERNAME", "")
  password <- Sys.getenv("MONTAGU_PASSWORD", "")

  if (nzchar(location)) {
    montagu::montagu_set_default_location(location)
  }
  if (nzchar(username)) {
    options(montagu.username = username)
  }
  if (nzchar(password)) {
    options(montagu.password = password)
  }
  montagu::montagu_authorise()
  dropbox_login()
}

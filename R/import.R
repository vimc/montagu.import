stochastic_upload <- function(d, local_path = "dropbox", lines = 20000,
                              index = NULL) {
  d$index <- index %||%  d$index_start:d$index_end
  info <- read_dropbox_info(d$dropbox, local_path)
  p_uploaded <- path_uploaded(local_path, d$dropbox)
  if (file.exists(p_uploaded)) {
    prev <- readRDS(p_uploaded)
    if (setequal(prev$content_hash, info$content_hash)) {
      message(d$dropbox, " is up to date")
      return(FALSE)
    }
  }

  cert <- download_certificate(d, info, local_path)
  files <- download_estimates(d, info, local_path)

  id <- montagu::montagu_burden_estimate_set_create(
    d$group, d$touchstone, d$scenario, "stochastic", cert$id)
  on.exit(
    montagu::montagu_burden_estimate_set_clear(
      d$group, d$touchstone, d$scenario, id))

  last_file <- files[[length(files)]]
  for (path in files) {
    montagu::montagu_burden_estimate_set_upload(
      d$group, d$touchstone, d$scenario, id, path, lines = lines,
      keep_open = path != last_file)
  }
  on.exit()
  TRUE
}

stochastic_clear <- function(d) {
  dat <- montagu::montagu_burden_estimates(d$group, d$touchstone, d$scenario)
  f <- function(x) x$type$type == "stochastic" && x$status == "partial"
  for (x in dat[vapply(dat, f, logical(1))]) {
    montagu::montagu_burden_estimate_set_clear(
      d$group, d$touchstone, d$scenario, x$id)
  }
}

download_certificate <- function(d, info, local_path) {
  cert <- download_dropbox_file(d$certfile, info, local_path)
  ret <- jsonlite::fromJSON(read_file(cert), simplifyVector = FALSE)
  c(ret[[1]], ret[[2]])
}

download_estimate <- function(d, index, info, local_path) {
  repl <- list(disease = d$disease,
               group = d$group,
               scenario = d$scenario,
               index = index)
  filename <- d$filename
  for (v in names(repl)) {
    filename <- sub(paste0(":", v), repl[[v]], filename, fixed = TRUE)
  }

  download_dropbox_file(filename, info, local_path)
}

download_estimates <- function(d, info, local_path) {
  message("Downloading all estimates for ", d$dropbox)
  vapply(d$index, function(i)
    download_estimate(d, i, info, local_path),
    character(1))
}

path_info <- function(local_path, dropbox_path) {
  file.path(local_path, "info", dropbox_path)
}

path_uploaded <- function(local_path, dropbox_path) {
  file.path(local_path, "uploaded", dropbox_path)
}

path_file <- function(local_path, dropbox_path) {
  file.path(local_path, "files", sub("^/", "", dropbox_path))
}

## Base remotely
dropbox_base <- "File requests"
path_dropbox <- function(dropbox_path) {
  file.path(dropbox_base, dropbox_path)
}

dropbox_info <- function(paths, local_path) {
  for (p in paths) {
    message(sprintf("Fetching directory information for %s", p))
    info <- rdrop2::drop_dir(path_dropbox(p))
    dest <- path_info(local_path, p)
    dir.create(dirname(dest), FALSE, TRUE)
    saveRDS(info, dest)
  }
}

read_dropbox_info <- function(path, local_path) {
  p <- path_info(local_path, path)
  if (!file.exists(p)) {
    dropbox_info(path, local_path)
  }
  readRDS(p)
}

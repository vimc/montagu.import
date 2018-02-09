## It would be possible to make this properly resumable, but that
## requires that we can purge estimates just for the current file that
## is being uploaded (or detect later that a partial file was
## uploaded).  So I'm just doing it at the "everything done" level,
## which is not ideal because that takes a few hours.
stochastic_upload <- function(d, local_path = "dropbox", lines = 20000,
                              index = NULL, check = TRUE) {
  d$index <- index %||% d$index_start:d$index_end

  info <- read_dropbox_info(d$dropbox, local_path)

  if (stochastic_upload_status(d, info, local_path)) {
    message("Upload is already complete")
    return()
  }

  cert <- download_certificate(d, info, local_path)
  files <- download_estimates(dropbox_filename(d), info, local_path, check)

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

  browser()

  stochastic_upload_status_set(d, id, info, local_path)
  on.exit()

  ## At this point we need to write out something to the uploads path
  ## so that we know what was uploaded.  I think that this is most
  ## easily done with the info-by-files set?
  TRUE
}

stochastic_upload_status <- function(d, info = NULL, local_path = "dropbox") {
  p_uploaded <- path_uploaded(local_path, d$dropbox, d$group, d$scenario)
  if (!file.exists(p_uploaded)) {
    return(FALSE)
  }
  prev <- readRDS(p_uploaded)

  info <- info %||% read_dropbox_info(d$dropbox, local_path)
  d$index <- d$index_start:d$index_end
  files <- dropbox_filename(d)

  stopifnot(all(files %in% info$name))

  hash <- info$content_hash[match(files, info$name)]
  setequal(prev$name, files) && setequal(prev$content_hash, hash)
}

stochastic_upload_status_set <- function(d, id, info, local_path = "dropbox") {
  index_all <- d$index_start:d$index_end
  if (!setequal(d$index, index_all)) {
    return()
  }
  files <- dropbox_filename(d)
  stopifnot(all(files %in% info$name))
  hash <- info$content_hash[match(files, info$name)]
  dat <- list(id = id,
              name = files,
              content_hash = hash)
  p_uploaded <- path_uploaded(local_path, d$dropbox, d$group, d$scenario)
  dir.create(dirname(p_uploaded), FALSE, TRUE)
  message("Setting upload status")
  saveRDS(dat, p_uploaded)
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

download_estimates <- function(filenames, info, local_path, check = TRUE) {
  vapply(filenames, function(f)
    download_dropbox_file(f, info, local_path, check),
    character(1))
}

dropbox_filename <- function(d, index = d$index) {
  repl <- list(disease = d$disease,
               group = d$group,
               scenario = d$scenario,
               index = "%d")
  filename <- d$filename
  for (v in names(repl)) {
    filename <- sub(paste0(":", v), repl[[v]], filename, fixed = TRUE)
  }
  sprintf(filename, index)
}

path_info <- function(local_path, dropbox_path) {
  file.path(local_path, "info", dropbox_path)
}

path_uploaded <- function(local_path, dropbox, group, scenario) {
  file.path(local_path, "uploaded",
            sprintf("%s__%s__%s.rds", dropbox, group, scenario))
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

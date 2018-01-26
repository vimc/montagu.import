dropbox_base <- "File requests"

dropbox_login <- function(renew = FALSE) {
  vault_path <- "/secret/import/dropbox-token"
  vault <- vaultr::vault_client()

  token <- vault$read(vault_path)
  if (renew || is.null(token)) {
    token <- rdrop2::drop_auth(cache = FALSE)
    token_str <- base64enc::base64encode(serialize(token, NULL, version = 2L))
    vault$write(vault_path, list(value = token_str))
  } else {
    token <- base64enc::base64decode(vault$read(vault_path, "value"))
    tmp <- tempfile()
    writeBin(token, tmp)
    on.exit(unlink(tmp))
    token <- rdrop2::drop_auth(cache = FALSE, rdstoken = tmp)
  }
  invisible(token)
}

download_certificate <- function(d) {
  path <- sprintf("File requests/%s/%s", d$dropbox, d$certfile)
  tmp <- drop_download2(path)
  on.exit(unlink(tmp))
  ret <- jsonlite::fromJSON(read_file(tmp), simplifyVector = FALSE)
  c(ret[[1]], ret[[2]])
}

drop_download2 <- function(path, dest = tempfile()) {
  dest_dl <- paste0(dest, ".dl")
  unlink(dest_dl)
  on.exit(unlink(dest_dl))
  dir.create(dirname(dest), FALSE, TRUE)
  ans <- tryCatch(rdrop2::drop_download(path, dest_dl),
                  http_error = function(e) e)
  if (inherits(ans, "http_error")) {
    info <- jsonlite::fromJSON(read_file(dest_dl), simplifyVector = FALSE)
    if (!is.null(info$error_summary)) {
      ans$message_original <- ans$message
      ans$message <- sprintf("Error downloading file: %s", info$error_summary)
    }
    stop(ans)
  }
  file.rename(dest_dl, dest)
  invisible(dest)
}

dropbox_content_hash <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  block_size <- 4L * 1024L * 1024L

  n <- ceiling(file.size(path) / block_size)
  h <- vector("list", n)
  for (i in seq_len(n)) {
    bytes <- readBin(con, raw(1), block_size)
    h[[i]] <- openssl::sha256(bytes)
  }

  as.character(openssl::sha256(unlist(h)))
}

## TODO: how will we cache these?  We can use md5 perhaps
download_estimate <- function(d, index, local_path) {
  repl <- list(disease = d$disease,
               group = d$group,
               scenario = d$scenario,
               index = index)
  filename <- d$filename
  for (v in names(repl)) {
    filename <- sub(paste0(":", v), repl[[v]], filename, fixed = TRUE)
  }

  index <- read_dropbox_index(d$dropbox, local_path)
  i <- match(filename, index$name)
  if (any(is.na(i))) {
    stop("File not found: ",
         paste0("\n  - %s", filename[is.na(i)], collapse = ""))
  }

  dest <- path_file(local_path, file.path(d$dropbox, filename))
  hash_expected <- index$content_hash[i]

  if (file.exists(dest)) {
    if (dropbox_content_hash(dest) == hash_expected) {
      message(dest, " is up to date")
      return(dest)
    }
  }

  drop_download2(file.path(dropbox_base, d$dropbox, filename), dest)

  message("verifying...")
  hash_received <- dropbox_content_hash(dest)
  if (hash_expected != hash_received) {
    file.rename(dest, paste0(dest, ".corrupted"))
    stop("Downloaded file failed verification")
  }

  dest
}

path_index <- function(local_path, dropbox_path) {
  file.path(local_path, "index", dropbox_path)
}

path_uploaded <- function(local_path, dropbox_path) {
  file.path(local_path, "uploaded", dropbox_path)
}

path_file <- function(local_path, dropbox_path) {
  file.path(local_path, "files", dropbox_path)
}

path_dropbox <- function(dropbox_path) {
  file.path(dropbox_base, dropbox_path)
}

dropbox_index <- function(paths, local_path) {
  for (p in paths) {
    message(sprintf("Fetching index for %s", p))
    info <- rdrop2::drop_dir(path_dropbox(p))
    dest <- path_index(local_path, p)
    dir.create(dirname(dest), FALSE, TRUE)
    saveRDS(info, dest)
  }
}

read_dropbox_index <- function(path, local_path) {
  p <- path_index(local_path, path)
  if (!file.exists(p)) {
    dropbox_index(path, local_path)
  }
  readRDS(p)
}

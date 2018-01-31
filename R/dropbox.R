## Submitted to rdrop2 as rdrop2::drop_content_hash
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

download_dropbox_file <- function(filename, info, local_path) {
  i <- which(info$name == filename)
  if (length(i) != 1L) {
    stop(sprintf("Error getting file info for %s (check metadata csv)",
                 filename))
  }

  path <- info$path_display[[i]]
  dest <- path_file(local_path, path)
  hash <- info$content_hash[[i]]

  download_if_unchanged(path, dest, hash)
}

download_if_unchanged <- function(path, dest, hash) {
  if (file.exists(dest) && dropbox_content_hash(dest) == hash) {
    message(dest, " is up to date")
    return(dest)
  }
  drop_download2(path, dest)

  message("verifying...")
  hash_received <- dropbox_content_hash(dest)
  if (hash_received != hash) {
    file.rename(dest, paste0(dest, ".corrupted"))
    stop("Downloaded file failed verification")
  }

  dest
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

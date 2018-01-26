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
  ans <- tryCatch(rdrop2::drop_download(path, dest),
                  http_error = function(e) e)
  if (inherits(ans, "http_error")) {
    info <- jsonlite::fromJSON(read_file(dest), simplifyVector = FALSE)
    if (!is.null(info$error_summary)) {
      ans$message_original <- ans$message
      ans$message <- sprintf("Error downloading file: %s", info$error_summary)
    }
    stop(ans)
  }
  invisible(dest)
}

## TODO: how will we cache these?  We can use md5 perhaps
download_estimate <- function(d, index) {
  repl <- list(disease = d$disease,
               group = d$group,
               scenario = d$scenario,
               index = index)
  filename <- d$filename
  for (v in names(repl)) {
    filename <- sub(paste0(":", v), repl[[v]], filename, fixed = TRUE)
  }
  filename <- file.path("File requests", d$dropbox, filename)

  drop_download2(filename)
}

read_file <- function(path) {
  rawToChar(readBin(path, raw(), file.size(path)))
}

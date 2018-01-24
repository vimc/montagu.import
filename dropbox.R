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
  tmp <- tempfile()
  on.exit(unlink(tmp))
  rdrop2::drop_download(path, tmp)
  ret <- jsonlite::fromJSON(read_file(tmp), simplifyVector = FALSE)
  c(ret[[1]], ret[[2]])
}

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

  rdrop2::drop_exists(filename)
  tmp <- tempfile()
  rdrop2::drop_download(filename, tmp)
  tmp
}

read_file <- function(path) {
  rawToChar(readBin(path, raw(), file.size(path)))
}

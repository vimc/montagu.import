read_file <- function(path) {
  rawToChar(readBin(path, raw(), file.size(path)))
}

read_csv <- function(...) {
  read.csv(..., stringsAsFactors = FALSE)
}

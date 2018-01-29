library(jsonlite)

host <- Sys.getenv("MONTAGU_DB_HOST", "support.montagu.dide.ic.ac.uk")
port <- as.integer(Sys.getenv("MONTAGU_DB_PORT", 5432))
user <- Sys.getenv("MONTAGU_DB_USER", "readonly")
password <- Sys.getenv("MONTAGU_DB_PASSWORD", "changeme")

con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "montagu",
                      host = host,
                      port = port,
                      password = password,
                      user = user)


read_file <- function(path) {
  rawToChar(readBin(path, raw(), file.size(path)))
}


test_file_existence <- function() {
  for (s in seq_len(nrow(dropboxes))) {
    entry <- dropboxes[s,]
    
    if (!file.exists(paste0(root, entry$dropbox, "/", entry$certfile))) {
      message(sprintf("Error - missing cert file %s for %s %s", 
                      entry$certfile, entry$group, entry$scenario))
    }
    
    f <- entry$filename
    f <- gsub(":disease", entry$disease, f)
    f <- gsub(":group", entry$group, f)
    f <- gsub(":scenario", entry$scenario, f)
    
    if (!is.na(entry$index_start)) {
      for (x in (entry$index_start:entry$index_end)) {
        f2 <- gsub(":index", x, f)
        if (!file.exists(paste0(root, entry$dropbox, "/", f2))) {
          message(sprintf("Error - missing data file %s for %s %s", 
                          f2, entry$group, entry$scenario))
        }
      }
      
    } else {
      if (!file.exists(paste0(root, entry$dropbox, "/", f))) {
        message(sprintf("Error - missing data file %s for %s %s", 
                        f, entry$group, entry$scenario))
      }
    }
  }
}

test_touchstone_consistency <- function() {
  for (s in seq_len(nrow(dropboxes))) {
    entry <- dropboxes[s, ]
    certfile <- paste0(root, entry$dropbox, "/", entry$certfile)
    cert <- jsonlite::fromJSON(read_file(certfile), simplifyVector = FALSE)
    params_id <- cert[[1]]$id
    mrps_touchstone <- DBI::dbGetQuery(con, 
      "SELECT touchstone FROM model_run_parameter_set 
         JOIN responsibility_set 
           ON responsibility_set.id=model_run_parameter_set.responsibility_set
        WHERE model_run_parameter_set.id=$1",params_id)$touchstone
  
    if (mrps_touchstone!=entry$touchstone) {
      message(sprintf("Mis-matched touchstone for %s. %s should be %s"
        ,paste0(entry$dropbox), entry$touchstone, mrps_touchstone))
    }
  }
}


dropboxes <- read.csv("dropbox_stochastic.csv", stringsAsFactors = FALSE)
#root <- "https://www.dropbox.com/File Requests"
root <- "E:/DROPBOX/Dropbox (SPH Imperial College)/File requests"

test_file_existence()
test_touchstone_consistency()

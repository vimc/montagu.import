dropboxes <- read.csv("dropbox_stochastic.csv", stringsAsFactors = FALSE)
#root <- "https://www.dropbox.com/File Requests"
root <- "E:/DROPBOX/Dropbox (SPH Imperial College)/File requests"

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

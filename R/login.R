montagu_login <- function(name) {
  vault <- vaultr::vault_client()
  if (name == "uat") {
    host <- "support.montagu.dide.ic.ac.uk"
    port <- 10443
  } else if (name == "science") {
    host <- "support.montagu.dide.ic.ac.uk"
    port <- 11443
  } else if (name == "production") {
    host <- "montagu.vaccineimpact.org"
    port <- 443
  } else {
    stop(sprintf("Unknown montagu server '%s'", name))
  }
  username <- "import"
  password <- vault$read("/secret/import/montagu", field = "password")
  server <- montagu::montagu_server(name, host, port = port,
                                    username = username, password = password,
                                    global = TRUE, overwrite = TRUE)
  montagu::montagu_server_global_default_set(server)
  message(sprintf("logged onto montagu server '%s'", name))
}

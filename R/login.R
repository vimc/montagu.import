montagu_login <- function(name) {
  vault <- vaultr::vault_client(login = "github")
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
  username <- "kimwoodruff80@gmail.com"
  password <- vault$read("/secret/import/montagu", field = "password")
  server <- montagu::montagu_server(name, host, port = port,
                                    username = username, password = password,
                                    global = TRUE, overwrite = TRUE)
  server$authorise()
  montagu::montagu_server_global_default_set(server)
  message(sprintf("logged onto montagu server '%s'", name))
}

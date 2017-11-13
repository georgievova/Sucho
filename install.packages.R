required_packages <- c("flexdashboard",
                       "leaflet",
                       "rgdal",
                       "data.table",
                       "ggplot2",
                       "GGally",
                       "DBI",
                       "odbc",
                       "dplyr",
                       "dbplyr",
                       "dygraphs",
                       "sp",
                       "knitr",
                       "shiny",
                       "DT",
                       "rgeos",
                       "datasets",
                       "xts",
                       "rmapshaper",
                       "maptools",
                       "stringr")
missing_packages <-
  required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}
rm("missing_packages")
rm("required_packages")

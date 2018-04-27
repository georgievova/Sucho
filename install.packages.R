required_packages <- c("flexdashboard",
                       "leaflet",
                       "htmltools",
                       "data.table",
                       "ggplot2",
                       "dplyr",
                       "plyr",
                       "dygraphs",
                       "sp",
                       "knitr",
                       "shiny",
                       "DT",
                       "psych",
                       "rgeos",
                       "xts",
                       "rhandsontable",
                       "plotly")
missing_packages <-
  required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}
rm("missing_packages")
rm("required_packages")

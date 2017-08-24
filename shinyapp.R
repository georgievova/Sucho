library(shiny)
#--------------------
#Load data
#--------------------
povodi <- readOGR("data/prep/povodi.shp")
reky <- readOGR("data/prep/reky.shp")
jezera <- readOGR("data/prep/jezera.shp")
popis <- read.table('data/E_ISVS$UTV_POV.txt',encoding = 'UTF-8', header = TRUE, sep=';')

# Merging data
#--------------------
povodi <- merge(povodi, popis, by='UPOV_ID')


ui <- fluidPage(
  titlePanel("Útvary povrchových vod ČR"),
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput("vyber", label = "Zobrazení povodí:", 
                         choices =  c("Řeky"="R","Jezera"="J"), selected= c("J", "R"))),
    mainPanel(
      leafletOutput("Leaflet"))
    )
)

server <- function(input, output){
  output$Leaflet <- renderLeaflet({
    #Select subset based on input
    #--------------------
    dta <- subset(povodi, as.character(povodi$KTGUPOV_Z) %in% input$vyber)
    
    # Creating labels
    #--------------------
    labels <- sprintf(
      "<strong>%s</strong><br/>Kategorie: %s<br/>Stav: %s <br/> ID: %s",
      dta$NAZ_UTVAR, dta$KTG_UPOV, dta$U_PMU, dta$UPOV_ID
    ) %>% lapply(htmltools::HTML)
    
    if(length(labels)==0){labels <- c(" ")}
    
    #Creating leaflet
    #--------------------
    leaflet() %>%
      addTiles(group = "Mapový podklad")%>%
      #addProviderTiles(providers$)%>%
      addPolygons(data=dta, color = "#999966", weight = 2, opacity = 1, 
                  fillColor = "#ccff99" , fillOpacity = 0.5, group = "Povodí",
                  highlightOptions = highlightOptions(color = "#CA5557", fillOpacity = 0, weight = 2.3, 
                                                      bringToFront = TRUE, sendToBack=TRUE),
                  label = labels,
                  labelOptions = labelOptions(clickable = TRUE, style = list("font-weight" = "normal", 
                                                                             "font-family" = "sans-serif", padding = "3px 8px",
                                                                             keepInView = TRUE,
                                                                             "border-color" = "rgb(255, 255, 255)"),
                                              textsize = "15px", direction = "auto"))%>%
      addPolylines(data=reky, color="#007C8C", weight = 1.5,
                   opacity = 1, stroke= TRUE, group = "Řeky") %>%
      addPolygons(data=jezera, color="#007C8C", fillColor = "#0099ff", 
                  weight = 1, opacity = 1, stroke= TRUE, group = "Jezera") %>%
      addLayersControl(overlayGroups = c("Mapový podklad", "Povodí", "Řeky", "Jezera"),
                       options = layersControlOptions(collapsed = FALSE))
  })
  }

shinyApp(ui = ui, server = server)

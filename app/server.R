#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
###############################Install Related Packages #######################
if (!require("shiny")) {
  install.packages("shiny")
  library(shiny)
}
if (!require("leaflet")) {
  install.packages("leaflet")
  library(leaflet)
}
if (!require("leaflet.extras")) {
  install.packages("leaflet.extras")
  library(leaflet.extras)
}
if (!require("dplyr")) {
  install.packages("dplyr")
  library(dplyr)
}
if (!require("magrittr")) {
  install.packages("magrittr")
  library(magrittr)
}
if (!require("mapview")) {
  install.packages("mapview")
  library(mapview)
}
if (!require("leafsync")) {
  install.packages("leafsync")
  library(leafsync)
}

library(urbnmapr) 
library(ggplot2)  
library(dplyr)   
library(tidyr)   
library(stringr) 
library(maps)
library(sf)
library(plotly)


usgeo = st_read("../data/cb_2018_us_county_20m/cb_2018_us_county_20m.shp") %>%
  mutate(fips = as.numeric(paste0(STATEFP, COUNTYFP)))
usgeo_county = sf::st_transform(usgeo, "+proj=longlat +datum=WGS84")

usgeo_state = st_read("../data/cb_2018_us_state_20m/cb_2018_us_state_20m.shp")
usgeo_state = sf::st_transform(usgeo_state, "+proj=longlat +datum=WGS84")

urlfile = "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries.csv"
disaster_df = read.csv(urlfile)

disaster_df$FIPScode = paste0(
  formatC(
    disaster_df$fipsStateCode, width = 2, flag = "0"), 
  formatC(
    disaster_df$fipsCountyCode, width = 3, flag = "0"))

disaster_df$startYear = substr(disaster_df$incidentBeginDate, 1, 4)

disaster_df$endYear = ifelse(
  disaster_df$incidentEndDate != "" & disaster_df$incidentEndDate > disaster_df$declarationDate,
  substr(disaster_df$incidentEndDate, 1, 4),
  disaster_df$startYear
)

grouped_disaster_df = disaster_df %>%
  group_by(startYear, endYear, FIPScode, state, fipsStateCode, designatedArea,) %>%
  summarize(count = n())

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

  updateDropdown = reactive({
    choices_year = sort(unique(grouped_disaster_df$endYear), decreasing = TRUE)
    updateSelectInput(session, "year_select", choices = choices_year)
    
    choices_state = c("Select State", sort(unique(grouped_disaster_df$state), decreasing = FALSE))
    updateSelectInput(session, "state_select", choices = choices_state)
  })
  
  # Call the updateDropdown reactive expression to update the dropdown choices
  observe({
    updateDropdown()
  })
  
  output$disaster_map = renderLeaflet({
    disaster_summary = subset(grouped_disaster_df, endYear <= input$year_select & startYear >= input$year_select)
    
    disaster_summary = st_as_sf(disaster_summary %>%
                                  left_join(usgeo, by = c("FIPScode" = "GEOID")))
    disaster_summary$geometry = st_zm(disaster_summary$geometry, drop = T, what = "ZM")
    disaster_summary = sf::st_transform(disaster_summary, "+proj=longlat +datum=WGS84")
    
    disasterpopup = paste0("County: ", disaster_summary$NAME, ", disaster count = ", disaster_summary$count)
    
    disasterPalette = colorNumeric(palette = "viridis", disaster_summary$count, reverse = TRUE)
    
    mymap = leaflet(disaster_summary) %>%
                  addProviderTiles("CartoDB.Positron") %>%
                  addPolygons(stroke=TRUE,
                              smoothFactor = 0.2,
                              fillOpacity = 1,
                              popup = disasterpopup,
                              color = ~disasterPalette(disaster_summary$count),
                              group = "count",
                              label = ~NAME,
                              labelOptions = labelOptions(textsize = "18px"),
                              highlight = highlightOptions(
                                weight = 3,
                                fillOpacity = 1,
                                color = "black",
                                opacity = 1.0,
                                bringToFront = TRUE,
                                sendToBack = TRUE)) %>%
                  addPolylines(data = usgeo_state, color = "black", opacity = 1, weight = 1) %>% 
                  addPolylines(data = usgeo_county, color = "black", opacity = 0.5, weight = 0.5) %>% 
                  addLegend(position = "topright", 
                            pal = disasterPalette, values = disaster_summary$count,
                             title = "Number of<br>Disasters",
                             opacity = 1
                  ) 

    if (input$state_select == "Select State" || input$state_select == "" || is.na(input$state_select)) {
      mymap %>% setView(lng = -98.5795, lat = 39.8283, zoom = 4)
    }
    else {
      state_coord = subset(usgeo_state, STUSPS == input$state_select)
      centroid_coords = st_coordinates(st_centroid(state_coord$geometry[1]))
      y = as.numeric(centroid_coords[, "Y"])
      x = as.numeric(centroid_coords[, "X"])
      mymap %>% setView(lng = x, lat = y, zoom = 6) 
    }
    
  })
 
  output$disaster_plot = renderPlotly({
    grouped_subset = subset(disaster_df, endYear <= input$year_select  & startYear >= input$year_select)
    
    if (input$state_select == "Select State" || input$state_select == "" || is.na(input$state_select)) {
      gg_chart = ggplot(grouped_subset, aes(x = state, fill = incidentType)) +
        geom_bar() +
        coord_flip() +
        labs(title = "Incident Types by State", x = "State", y = "Count") +
        scale_fill_viridis_d("Incident Type") 
      
      ggplotly(gg_chart, tooltip = c("state", "incidentType", "y"))
    }
    else {
      grouped_subset_state = subset(grouped_subset, state == input$state_select)
      grouped_subset_state = grouped_subset_state %>%
                                left_join(usgeo, by = c("FIPScode" = "GEOID"))
      gg_chart = ggplot(grouped_subset_state, aes(x = NAME, fill = incidentType)) +
        geom_bar() +
        coord_flip() +
        labs(title = "Incident Types by Counties", x = "County", y = "Count") +
        scale_fill_viridis_d("Incident Type") 
      
      ggplotly(gg_chart, tooltip = c("NAME", "incidentType", "y"))
    }
    
  })
  
})




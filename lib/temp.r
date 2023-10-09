library(shiny)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(magrittr)
library(mapview)
library(leafsync)
library(urbnmapr) 
library(ggplot2)  
library(dplyr)   
library(tidyr)   
library(stringr) 
library(maps)
library(sf)


usgeo = st_read("./data/cb_2018_us_county_20m/cb_2018_us_county_20m.shp") %>%
  mutate(fips = as.numeric(paste0(STATEFP, COUNTYFP)))
usgeo_county = sf::st_transform(usgeo, "+proj=longlat +datum=WGS84")

usgeo_state = st_read("./data/cb_2018_us_state_20m/cb_2018_us_state_20m.shp")
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

################################################ MAP STUFF ###########################################################

grouped_disaster_df = disaster_df %>%
  group_by(startYear, endYear, FIPScode, state,
           fipsStateCode,
           designatedArea,) %>%
  summarize(
    count = n()
  )



disaster_summary = subset(grouped_disaster_df, endYear <= 2023 & startYear >= 2023)

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

mymap %>% setView(lng = -98.5795, lat = 39.8283, zoom = 4)

      
################################################ Bar graph STUFF ###########################################################
      
colnames(disaster_df)

head(disaster_df[, c("incidentType", "declarationTitle", "state", "fipsStateCode", "fipsCountyCode" )])

grouped_subset = subset(disaster_df, endYear <= 2023 & startYear >= 2023)

library(plotly)

gg_chart = ggplot(grouped_subset, aes(x = state, fill = incidentType)) +
  geom_bar() +
  coord_flip() +
  labs(title = "Incident Types by State", x = "State", y = "Count") +
  scale_fill_viridis_d("Incident Type") 

ggplotly(gg_chart, tooltip = c("state", "incidentType", "y"))


grouped_subset_df = grouped_subset %>%
  group_by(state,incidentType) %>%
  summarize(
    count = n()
  )

grouped_subset_state = subset(grouped_subset, state == "CA")

grouped_subset_state = grouped_subset_state %>%
  left_join(usgeo, by = c("FIPScode" = "GEOID"))

grouped_subset_df = grouped_subset_state %>%
  group_by(state,incidentType, NAME) %>%
  summarize(
    count = n()
  )

print(nrow(grouped_subset_state))

gg_chart = ggplot(grouped_subset_state, aes(x = NAME, fill = incidentType)) +
  geom_bar() +
  coord_flip() +
  labs(title = "Incident Types by Counties", x = "County", y = "Count") +
  scale_fill_viridis_d("Incident Type") 

ggplotly(gg_chart, tooltip = c("NAME", "incidentType", "y"))






max_count = max(grouped_subset_df$count)

disaster_list = unique(grouped_subset_df$incidentType)

fig <- plot_ly(
  type = 'scatterpolar',
  fill = 'toself',
  mode = "markers"
) 
for (x in disaster_list) {
  subset_df = subset(grouped_subset_df, incidentType == x)
  fig <- fig %>%
    add_trace(
      r = subset_df$count,
      theta = subset_df$NAME,
      name = x,
      mode = "markers",
      marker = list(
        colorscale = "viridis"  # Set Viridis color palette
      )
    ) 
}
fig <- fig %>%
  layout(
    polar = list(
      radialaxis = list(
        visible = T,
        range = c(0,max_count)
      )
    )
  )

fig

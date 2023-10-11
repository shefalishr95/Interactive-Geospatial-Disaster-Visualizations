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

library(tidytext)
library(DT)
library(scales)
library(wordcloud2)
library(gridExtra)
library(tm)
library(ngram)


usgeo = st_read("./data/cb_2018_us_county_20m/cb_2018_us_county_20m.shp") %>%
  mutate(fips = as.numeric(paste0(STATEFP, COUNTYFP)))
usgeo_county = sf::st_transform(usgeo, "+proj=longlat +datum=WGS84")

usgeo_state = st_read("./data/cb_2018_us_state_20m/cb_2018_us_state_20m.shp")
usgeo_state = sf::st_transform(usgeo_state, "+proj=longlat +datum=WGS84")

urlfile_claims = "./data/FimaNfipClaims.csv"
your_dataset_insurance = read.csv(urlfile_claims)

url_file_inventories="https://www.fema.gov/api/open/v1/HmaSubapplicationsProjectSiteInventories.csv"
your_dataset_inventories = read.csv(url_file_inventories)

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
  ##### TAB 1 #################
  updateDropdown = reactive({
    choices_year = sort(unique(grouped_disaster_df$endYear), decreasing = TRUE)
    updateSelectInput(session, "year_select", choices = choices_year)
    
    choices_state = c("Select State", sort(unique(grouped_disaster_df$state), decreasing = FALSE))
    updateSelectInput(session, "state_select", choices = choices_state)
    updateSelectInput(session, "state_select_tab2", choices = choices_state)
    updateSelectInput(session, "state_select_tab3", choices = choices_state)
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
  
  ############# TAB 2 ############################
  filteredData = eventReactive(input$updateData, {
    req(input$state_select_tab2)
    filter(your_dataset_insurance, propertyState == input$state_select_tab2)
  })
  
  output$premiumComparison = renderPlotly({
    if (nrow(filteredData()) > 0) {
      avg_values = summarise(
        filteredData(),
        Avg_Premium = mean(your_dataset_insurance$totalInsurancePremiumOfThePolicy),
        Avg_Building_Coverage = mean(your_dataset_insurance$totalBuildingInsuranceCoverage),
        Avg_Contents_Coverage = mean(your_dataset_insurance$totalContentsInsuranceCoverage)
      )
      
      avg_values_long = pivot_longer(avg_values, cols = starts_with("Avg_"), names_to = "Category", values_to = "Average")
      
      insurance_plot = ggplot(avg_values_long, aes(x = Category, y = Average, fill = Category)) +
        geom_bar(stat = "identity") +
        labs(
          title = "Average Insurance Premiums and Coverages",
          x = "Category",
          y = "Average Value",
          fill = "Category"
        ) +
        scale_fill_viridis_d("Category")  +
        theme(legend.position = "none")

      ggplotly(insurance_plot, tooltip = c("Average"))
    }
    else {
      plot(NULL, xlim = c(0, 1), ylim = c(0, 1), xlab = "", ylab = "")  # Empty plot if propertyState is not found
    }
  })
  # 
  # filteredData = eventReactive(input$updateData, {
  #   req(input$state_select_tab2)
  #   if (input$state_select_tab2 %in% your_dataset_inventories$stateAbbreviation) {
  #     filter(your_dataset_inventories, stateAbbreviation == input$state_select_tab2)
  #   } else {
  #     data.frame()  # Empty data frame if state Abbreviation is not found
  #   }
  # })
  # 
  # output$priceDistribution = renderPlot({
  #   ggplot(filteredData(), aes(x = estimatedPurchasePrice)) +
  #     geom_histogram(binwidth = 5000, fill = "blue", color = "black") +
  #     labs(title = "Estimated Purchase Price Distribution")
  # })
  # 
  # output$ratioDistribution = renderPlot({
  #   ggplot(filteredData(), aes(x = benefitCostRatio)) +
  #     geom_histogram(binwidth = 0.1, fill = "green", color = "black") +
  #     labs(title = "Benefit Cost Ratio Distribution")
  # })
  # 
  # output$averagePrice = renderText({
  #   if (nrow(filteredData()) > 0) {
  #     avg_price = mean(filteredData()$estimatedPurchasePrice)
  #     paste("Average Estimated Purchase Price:", format(avg_price, big.mark = ",", scientific = FALSE))
  #   } else {
  #     "State Code not found"
  #   }
  # })
  # 
  # output$averageRatio = renderText({
  #   if (nrow(filteredData()) > 0) {
  #     avg_ratio = mean(filteredData()$benefitCostRatio)
  #     paste("Average Benefit Cost Ratio:", round(avg_ratio, 2))
  #   } else {
  #     "State Code not found"
  #   }
  # })
  
  
  ########### TAB 3####################
  filteredData = reactive({
    req(input$generateButton)
    req(input$state_select_tab3)
    
    # Filter data based on input location
    filter(disaster_df, state == input$state_select_tab3)
  })
  
  # Generate word cloud
  output$wordcloudOutput = renderWordcloud2({
    if (nrow(filteredData()) == 0) {
      return(wordcloud(words = character(0), freq = numeric(0)))
    }
    
    # Create a corpus
    corpus = Corpus(VectorSource(filteredData()$declarationTitle))
    
    # Preprocess the text
    corpus = tm_map(corpus, content_transformer(tolower))
    corpus = tm_map(corpus, removePunctuation)
    corpus = tm_map(corpus, removeNumbers)
    corpus = tm_map(corpus, stripWhitespace)
    
    # Create a term-document matrix
    tdm = TermDocumentMatrix(corpus)
    
    # Convert term-document matrix to a matrix
    m = as.matrix(tdm)
    
    # Calculate word frequencies
    word_freqs = sort(rowSums(m), decreasing = TRUE)
    
    # Create a data frame for wordcloud2
    wordcloud_data = data.frame(word = names(word_freqs), freq = word_freqs)
    
    wordcloud2(wordcloud_data)
  })
  
  # Display information about the data
  output$infoText = renderText({
    if (nrow(filteredData()) == 0) {
      return("No data found for the specified location.")
    }
    
    paste("Showing data for", input$state_select_tab3)
  })
  
})





if (!require("shiny")) {
  install.packages("shiny")
  library(shiny)
}
if (!require("shinyWidgets")) {
  install.packages("shinyWidgets")
  library(shinyWidgets)
}
if (!require("shinythemes")) {
  install.packages("shinythemes")
  library(shinythemes)
}
if (!require("leaflet")) {
  install.packages("leaflet")
  library(leaflet)
}
if (!require("leaflet.extras")) {
  install.packages("leaflet.extras")
  library(leaflet.extras)
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

# Define UI for application that draws a histogram
shinyUI(
  navbarPage(strong("US Disaster Study",style="color: white;"), 
             theme=shinytheme("sandstone"), # select your themes https://rstudio.github.io/shinythemes/
             tabPanel("Introduction",
                      icon = icon("house"),
                      fluidRow (
                          h4(style =  "margin:20px", "Imagine you're on the verge of buying your dream home. You've saved up for a down payment and organized your finances. 
                          Now, you're ready to take the plunge. But before deciding on a location, wouldn't you like to know more about the county or state? What's the school quality like? 
                          How many public spaces are there? What's the transportation system like? And most importantly, how likely (or rather, unlikely) are natural or artificial disasters in the area?", width = "1500px"), 
                          
                          h4(style =  "margin:20px", "We've developed an app to help you answer this crucial question.", width = "1500px"),
                          
                          h4(style =  "margin:20px", "The app utilizes open datasets from the Federal Emergency Management Agency to provide historical data on number of disasters in your state, along with the average economic costs associated with those disasters. The main components of app are as follows:", width = "1500px"),
                          
                          tags$ul(
                            tags$li(
                              h4("County-wise disaster map")
                            ),
                            tags$li(
                              h4("Economic costs associated with disasters")
                            ),
                            tags$li(
                              h4("Word cloud of common disasters")
                            )
                          ),
                          
                          img(style =  "margin:20px", src='hurricane.png', align = "center", width = "1500px"),
                      )
             ),
             #------------------------------- tab panel - Maps ---------------------------------
             tabPanel("County-wise Disaster Map",
                      icon = icon("map-marker-alt"), #choose the icon for
                      fluidRow (
                        h4(style =  "margin:20px","This section uses open FEMA dataset to display the count of disasters by state, county, and year on the map of the United States. To see the count in your area, just select your state and county, and the year of interest. The map will automatically readjust to show you the number of disasters in the selected year in that area. Depending on the internet bandwidth and local memory, this map might take anywhere from 1 to 6 minutes to load – so please be patient!"),
                        
                        h4(style =  "margin:20px","As you scroll down, you'll encounter an alternate visualization—an informative bar plot. For all those who prefer seeing the numbers on a chart, we’ve created a bar plot illustrating the count of disasters in the selected year, county and state (meaning, you don’t need to re-select your specifications). Additionally, the bar plot also shows the number of disasters by category (such as ‘Fire’, ‘Flood’ etc.)")
                      ),
                      
                      sidebarLayout(
                              sidebarPanel (
                                    selectInput(inputId = "year_select",
                                                label = "Select a Year:",
                                                choices = NULL),
                                    selectInput(inputId = "state_select",
                                                label = "Select a State:",
                                                choices = NULL),
                                    width = 2
                                  ),
                                  mainPanel (
                                    tags$style(type="text/css",
                                               ".shiny-output-error { visibility: hidden; }",
                                               ".shiny-output-error:before { visibility: hidden; }"),
                                    leafletOutput("disaster_map", height = "600px"),
                                    plotlyOutput("disaster_plot", height = "1000px"),
                                    width = 10
                                  ),
                                  position = "left",
                                  fluid = TRUE
                              )
                      
            ), #tabPanel maps closing
            tabPanel("Economic Effects",
                     icon = icon("coins")
            ),
            tabPanel("Disaster Word Cloud",
                     icon = icon("cloud"),
                     fluidRow (
                       h4(style =  "margin:20px","Here, we have an interesting visualization for those who prefer words over numbers and figures. The Word Cloud presented below displays the most frequent disasters in your state, for the selected year, using scale as a dimension. That means, the most commonly occurring disaster in your area is the biggest word, and second most common disaster is the second biggest word, and so forth. This visualization provides a succinct representation of the most commonly encountered disasters in your locality."),
                        ),
                     sidebarLayout(
                       sidebarPanel (
                         selectInput(inputId = "state_select_tab3",
                                     label = "Select a State:",
                                     choices = NULL),
                         actionButton("generateButton", "Generate Word Cloud"),
                         width = 2
                       ),
                       mainPanel (
                         wordcloud2Output("wordcloudOutput"),
                         textOutput("infoText")
                       )
                     )
            )
  ) #navbarPage closing  
) #Shiny UI closing    
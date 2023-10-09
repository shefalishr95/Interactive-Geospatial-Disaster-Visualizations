
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

# Define UI for application that draws a histogram
shinyUI(
  navbarPage(strong("US Disaster Study",style="color: white;"), 
             theme=shinytheme("sandstone"), # select your themes https://rstudio.github.io/shinythemes/
             #------------------------------- tab panel - Maps ---------------------------------
             tabPanel("County-wise Disaster Map",
                      icon = icon("map-marker-alt"), #choose the icon for
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
            tabPanel("Cost",
                     icon = icon("coins")
            )
  ) #navbarPage closing  
) #Shiny UI closing    
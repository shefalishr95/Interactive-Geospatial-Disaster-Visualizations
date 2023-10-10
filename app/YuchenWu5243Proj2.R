library(tidytext)
library(DT)
library(scales)
library(wordcloud2)
library(gridExtra)
library(dplyr)
library(tm)
library(ngram)
library(shiny) 

data<- read.csv('C:/Users/Yuche/Desktop/STAT 5243/5243 Proj/DisasterDeclarationsSummaries.csv')
FEMA_data<- data[,c(1,2,3,4,5,6,7,8,17,18,19,20, 21)]
FEMA_data

ui <- fluidPage(
  titlePanel("Disaster of wordcloud"),
  sidebarLayout(
    sidebarPanel(
      textInput("locationInput", "Enter State Code:", ""),
      actionButton("generateButton", "Generate Word Cloud")
    ),
    mainPanel(
      wordcloud2Output("wordcloudOutput"),
      textOutput("infoText")
    )
  )
)

# Define server
server <- function(input, output) {
  # Create a reactive data frame
  filteredData <- reactive({
    req(input$generateButton)
    req(input$locationInput)
    
    # Filter data based on input location
    filter(FEMA_data, fipsStateCode == input$locationInput)
  })
  
  # Generate word cloud
  output$wordcloudOutput <- renderWordcloud2({
    if (nrow(filteredData()) == 0) {
      return(wordcloud(words = character(0), freq = numeric(0)))
    }
    
    # Create a corpus
    corpus <- Corpus(VectorSource(filteredData()$incidentType))
    
    # Preprocess the text
    corpus <- tm_map(corpus, content_transformer(tolower))
    corpus <- tm_map(corpus, removePunctuation)
    corpus <- tm_map(corpus, removeNumbers)
    corpus <- tm_map(corpus, stripWhitespace)
    
    # Create a term-document matrix
    tdm <- TermDocumentMatrix(corpus)
    
    # Convert term-document matrix to a matrix
    m <- as.matrix(tdm)
    
    # Calculate word frequencies
    word_freqs <- sort(rowSums(m), decreasing = TRUE)
    
    # Create a data frame for wordcloud2
    wordcloud_data <- data.frame(word = names(word_freqs), freq = word_freqs)
    
    wordcloud2(wordcloud_data, color = "random")
  })
  
  # Display information about the data
  output$infoText <- renderText({
    if (nrow(filteredData()) == 0) {
      return("No data found for the specified location.")
    }
    
    paste("Showing data for", input$locationInput)
  })
}

# Run the Shiny app
shinyApp(ui, server)
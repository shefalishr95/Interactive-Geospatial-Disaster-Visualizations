library(shiny)
library(ggplot2)
library(dplyr)

# Load your dataset
your_dataset <- read.csv("/Users/roy/Downloads/HmaSubapplicationsProjectSiteInventories.csv")  # Replace with your dataset file path

# Define the user interface
ui <- fluidPage(
  titlePanel("County Data Distribution"),
  sidebarLayout(
    sidebarPanel(
      textInput("countyCodeInput", "Enter County Code:", ""),
      actionButton("updateData", "Update Data")
    ),
    mainPanel(
      plotOutput("priceDistribution"),
      plotOutput("ratioDistribution"),
      verbatimTextOutput("averagePrice"),
      verbatimTextOutput("averageRatio")
    )
  )
)

# Define the server logic
server <- function(input, output, session) {
  
  filteredData <- eventReactive(input$updateData, {
    req(input$countyCodeInput)
    if (input$countyCodeInput %in% your_dataset$countyCode) {
      filter(your_dataset, countyCode == input$countyCodeInput)
    } else {
      data.frame()  # Empty data frame if countyCode is not found
    }
  })
  
  output$priceDistribution <- renderPlot({
    ggplot(filteredData(), aes(x = estimatedPurchasePrice)) +
      geom_histogram(binwidth = 5000, fill = "blue", color = "black") +
      labs(title = "Estimated Purchase Price Distribution")
  })
  
  output$ratioDistribution <- renderPlot({
    ggplot(filteredData(), aes(x = benefitCostRatio)) +
      geom_histogram(binwidth = 0.1, fill = "green", color = "black") +
      labs(title = "Benefit Cost Ratio Distribution")
  })
  
  output$averagePrice <- renderText({
    if (nrow(filteredData()) > 0) {
      avg_price <- mean(filteredData()$estimatedPurchasePrice)
      paste("Average Estimated Purchase Price:", format(avg_price, big.mark = ",", scientific = FALSE))
    } else {
      "County Code not found"
    }
  })
  
  output$averageRatio <- renderText({
    if (nrow(filteredData()) > 0) {
      avg_ratio <- mean(filteredData()$benefitCostRatio)
      paste("Average Benefit Cost Ratio:", round(avg_ratio, 2))
    } else {
      "County Code not found"
    }
  })
  
}

# Run the Shiny app
shinyApp(ui, server)

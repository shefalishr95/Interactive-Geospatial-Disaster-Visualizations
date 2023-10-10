library(shiny)
library(ggplot2)
library(dplyr)

# Load dataset
urrfile="https://www.fema.gov/api/open/v1/HmaSubapplicationsProjectSiteInventories.csv"
your_dataset <- read.csv(urrfile)
  
# Define the user interface
ui <- fluidPage(
  titlePanel("State Data Distribution"),
  sidebarLayout(
    sidebarPanel(
      textInput("stateCodeInput", "Enter State Code:", ""),
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
    req(input$stateCodeInput)
    if (input$stateCodeInput %in% your_dataset$stateAbbreviation) {
      filter(your_dataset, stateAbbreviation == input$stateCodeInput)
    } else {
      data.frame()  # Empty data frame if state Abbreviation is not found
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
      "State Code not found"
    }
  })
  
  output$averageRatio <- renderText({
    if (nrow(filteredData()) > 0) {
      avg_ratio <- mean(filteredData()$benefitCostRatio)
      paste("Average Benefit Cost Ratio:", round(avg_ratio, 2))
    } else {
      "State Code not found"
    }
  })
  
}

# Run the Shiny app
shinyApp(ui, server)

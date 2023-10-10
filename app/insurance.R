library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)  # Add this line to load the tidyr package

# Load your dataset
your_dataset <- read.csv("/Users/roy/Desktop/222.csv")  # Replace with your dataset file path

# Define the user interface
ui <- fluidPage(
  titlePanel("Insurance Premiums by County"),
  sidebarLayout(
    sidebarPanel(
      selectInput("countyCodeInput", "Select County Code:", choices = unique(your_dataset$countyCode)),
      actionButton("updateData", "Update Data")
    ),
    mainPanel(
      plotOutput("premiumComparison")
    )
  )
)

# Define the server logic
server <- function(input, output, session) {
  
  filteredData <- eventReactive(input$updateData, {
    req(input$countyCodeInput)
    filter(your_dataset, countyCode == input$countyCodeInput)
  })
  
  output$premiumComparison <- renderPlot({
    if (nrow(filteredData()) > 0) {
      avg_values <- summarise(
        filteredData(),
        Avg_Premium = mean(totalInsurancePremiumOfThePolicy),
        Avg_Building_Coverage = mean(totalBuildingInsuranceCoverage),
        Avg_Contents_Coverage = mean(totalContentsInsuranceCoverage)
      )
      
      avg_values_long <- pivot_longer(avg_values, cols = starts_with("Avg_"), names_to = "Category", values_to = "Average")
      
      ggplot(avg_values_long, aes(x = Category, y = Average, fill = Category)) +
        geom_bar(stat = "identity") +
        labs(
          title = "Average Insurance Premiums and Coverages",
          x = "Category",
          y = "Average Value",
          fill = "Category"
        ) +
        theme_minimal() +
        theme(legend.position = "none")
    } else {
      plot(NULL, xlim = c(0, 1), ylim = c(0, 1), xlab = "", ylab = "")  # Empty plot if countyCode is not found
    }
  })
  
}

# Run the Shiny app
shinyApp(ui, server)

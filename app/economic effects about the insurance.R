library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)  # Add this line to load the tidyr package

# Load your dataset
urrrfile="https://www.fema.gov/openfema-data-page/fima-nfip-redacted-claims-v2"
your_dataset <- read.csv(urrrfile)
# Define the user interface
ui <- fluidPage(
  titlePanel("Insurance Premiums by State"),
  sidebarLayout(
    sidebarPanel(
      selectInput("propertyStateInput", "Select State Code:", choices = unique(your_dataset$propertyState)),
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
    req(input$propertyStateInput)
    filter(your_dataset, propertyState == input$propertyStateInput)
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
      plot(NULL, xlim = c(0, 1), ylim = c(0, 1), xlab = "", ylab = "")  # Empty plot if propertyState is not found
    }
  })
  
}

# Run the Shiny app
shinyApp(ui, server)

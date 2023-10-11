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


urlfile = "https://www.fema.gov/api/open/v1/PublicAssistanceFundedProjectsSummaries.csv"
pafpr_df = read.csv(urlfile)

colnames(pafpr_df)









fig <- plot_ly(data, x = ~federalObligatedAmount, y = ~numberOfProjects, text = ~county,
               type = 'scatter', mode = 'markers', marker = list(size = sqrt(numberOfProjects), sizemode = 'diameter'))

fig <- fig %>%
  layout(
    title = "County-wise Federal Obligated Amount and Number of Projects",
    xaxis = list(title = "Federal Obligated Amount"),
    yaxis = list(title = "Number of Projects"),
    showlegend = FALSE
  )

fig



















filteredData = filter(disaster_df, state == "CA")

# Generate word cloud
  if (nrow(filteredData()) == 0) {
    return(wordcloud(words = character(0), freq = numeric(0)))
  }
  
  # Create a corpus
  corpus = Corpus(VectorSource(filteredData$incidentType))
  
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
  
  wordcloud2(data = wordcloud_data, colors = "viridis")
})
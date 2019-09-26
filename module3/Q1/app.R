library(shiny)
library(plyr)
library(tidyverse)
library(gganimate)
library(rvest)

mor_df <- read.csv("https://raw.githubusercontent.com/charleyferrari/CUNY_DATA_608/master/module3/data/cleaned-cdc-mortality-1999-2010-2.csv", 
                   stringsAsFactors=F) %>% filter(Year==2010)
cause_list <- mor_df %>% select(ICD.Chapter) %>% unique() %>% unlist() %>% unname() %>% as.list()

ui <- fluidPage(
  titlePanel("2010 Mortality Rates in the US, by Cause and State"),
  selectInput(inputId = "which_cause", label = "Cause of Deaths", choices = cause_list),
  actionButton(inputId = "go_button", label="Submit"),
  plotOutput("death_plot")
)

server <- function(input, output) {
  
  cause_opt <- eventReactive(input$go_button, input$which_cause)
  
  output$death_plot <- renderPlot({
    
    this_cause <- cause_opt()
    
    cause_df <- mor_df %>% filter(ICD.Chapter==this_cause) %>% arrange(desc(Crude.Rate))
    
    cause_df %>% 
      ggplot(aes(x=State, y=Crude.Rate)) + 
      geom_bar(stat="identity", position="dodge") + 
      coord_flip() + theme(axis.text.y = element_text(size=6)) + 
      scale_x_discrete(limits = rev(cause_df$State)) + 
      labs(title = "Mortality Rate By State", y="Deaths per 100,000 People", x="State") + 
      theme(legend.position = "none")
    
  })
}

shinyApp(ui = ui, server = server)

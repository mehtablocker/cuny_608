library(shiny)
library(plyr)
library(tidyverse)
library(gganimate)
library(rvest)

mor_df <- read.csv("https://raw.githubusercontent.com/charleyferrari/CUNY_DATA_608/master/module3/data/cleaned-cdc-mortality-1999-2010-2.csv", 
                   stringsAsFactors=F)
cause_list <- mor_df %>% select(ICD.Chapter) %>% unique() %>% unlist() %>% unname() %>% as.list()
state_list <- mor_df %>% select(State) %>% unique() %>% unlist() %>% unname() %>% as.list()

### Calculate national average by cause and bind to df
nat_df <- mor_df %>% group_by(Year, ICD.Chapter) %>% 
  summarise(Deaths=sum(Deaths), Population=sum(Population)) %>% 
  ungroup() %>% mutate(Crude.Rate = round(Deaths/Population*100000, 1), State="National")
mor_nat_df <- rbind.fill(mor_df, nat_df)
mor_nat_df$State <- factor(mor_nat_df$State, levels=c("National", unlist(state_list)))

ui <- fluidPage(
  titlePanel("US Mortality Rates Over Time, by State and Cause"),
  selectInput(inputId = "which_state", label = "US State", choices = state_list, multiple=T),
  selectInput(inputId = "which_cause", label = "Cause of Deaths", choices = cause_list),
  actionButton(inputId = "go_button", label="Submit"),
  plotOutput("death_plot")
)

server <- function(input, output) {
  
  state_opt <- eventReactive(input$go_button, input$which_state)
  cause_opt <- eventReactive(input$go_button, input$which_cause)
  
  output$death_plot <- renderPlot({
    
    this_state <- state_opt()
    this_cause <- cause_opt()
    
    cause_df <- mor_nat_df %>% filter(ICD.Chapter==this_cause, State %in% c("National", this_state))
    
    cause_df %>% 
      ggplot(aes(x=Year, y=Crude.Rate, group=State, colour=State)) + 
      geom_point() + geom_line() + 
      labs(title = "Mortality Rate Over Time", x="Year", y="Deaths per 100,000 People", colour="")
    
    
  })
}

shinyApp(ui = ui, server = server)

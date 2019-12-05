library(shiny)
library(plyr)
library(tidyverse)
library(gganimate)
library(rvest)

ui <- fluidPage(
  titlePanel("Animated US Treasury Yield Curve Chart"),
  dateInput(inputId = "start_date", label = "Start Date", value = Sys.Date()-370, min = "1991-01-01", max = Sys.Date()-10),
  dateInput(inputId = "end_date", label = "End Date", value = Sys.Date(), min = "1991-02-01", max = Sys.Date()),
  selectInput(inputId = "daily_monthly", label = "Daily, Monthly, or Yearly Intervals", choices = list("Monthly", "Daily", "Yearly")),
  actionButton(inputId = "go_button", label="Submit"),
  headerPanel(HTML('<font size="2"><em>Please limit the number of intervals in your query to fewer than 30.</em></font>')),
  imageOutput("animated_gif")
)

server <- function(input, output) {
  
  daily_monthly <- eventReactive(input$go_button, input$daily_monthly)
  start_date <- eventReactive(input$go_button, input$start_date)
  end_date <- eventReactive(input$go_button, input$end_date)
  
  output$animated_gif <- renderImage({
    
    start_date <- start_date()
    end_date <- end_date()
    daily_monthly <- daily_monthly()
    
    ### Show message while waiting for chart to load
    showModal(modalDialog("Getting the data and building the chart. This can take up to a minute. Please wait.", footer=NULL))
    
    ### Get rates data from github and scrape any newer data
    rates_df_raw <- read.csv("https://raw.githubusercontent.com/mehtablocker/cuny_618/master/us_treasury_historical_rates.csv", stringsAsFactors=F)
    names(rates_df_raw) <- names(rates_df_raw) %>% gsub("X", "", .) %>% gsub("\\.", " ", .)
    rates_df_raw <- rates_df_raw %>% mutate(Date=as.Date(Date, format="%m/%d/%Y"))
    start_year <- as.numeric(format(max(rates_df_raw$Date), "%Y"))
    end_year <- as.numeric(format(end_date, "%Y"))
    if (end_date>max(rates_df_raw$Date)){
      for (i in start_year:end_year){
        base_url <- "https://www.treasury.gov/resource-center/data-chart-center/interest-rates/Pages/TextView.aspx?data=yieldYear&year="
        full_url <- paste0(base_url, i)
        url_html <- full_url %>% read_html()
        table_list <- url_html %>% html_table(fill=T)
        new_rates_df <- table_list[[2]] %>% 
          mutate(Date=as.Date(Date, format="%m/%d/%y")) %>% 
          filter(Date>max(rates_df_raw$Date))
        rates_df_raw <- rbind.fill(rates_df_raw, new_rates_df)
      }
    }
    rates_df_raw <- suppressWarnings(rates_df_raw %>% mutate_at(vars(-Date), as.numeric))
    rates_df_filt <- rates_df_raw %>% filter(Date>=start_date, Date<=end_date)
    if (daily_monthly!="Daily"){
      rates_df_filt <- rates_df_filt %>% mutate(day_of_mth=format(Date, "%d")) %>% 
        filter(day_of_mth==format(max(Date), "%d")) %>% select(-day_of_mth)
      if (daily_monthly=="Yearly"){
        rates_df_filt <- rates_df_filt %>% mutate(mth_of_year=format(Date, "%m")) %>% 
          filter(mth_of_year==format(max(Date), "%m")) %>% select(-mth_of_year)
      }
    }
    rates_df <- rates_df_filt %>% gather(Term, value, 2:ncol(rates_df_raw), factor_key=T) %>% spread(Date, value)
    rates_df_long <- rates_df %>% 
      gather(Date, Rate, -Term) %>% 
      mutate(Date=as.Date(Date),
             Day_Number=as.numeric(Date-min(Date))+1)
    
    # A temp file to save the output.
    # This file will be removed later by renderImage
    outfile <- tempfile(fileext='.gif')
    
    p1 <- ggplot(rates_df_long, aes(x = Term, y = Rate))+
      geom_col() +
      labs(title = 'US YIELD CURVE \n Date: {frame_time}', x = 'Term', y = 'Rate')+
      transition_time(Date)
    
    anim_save("outfile.gif", animate(p1, fps = 10, duration = 15, end_pause = 45))
    
    ### Remove the waiting message
    removeModal()
    
    # Return a list containing the filename
    list(src = "outfile.gif",
         contentType = 'image/gif'
         # width = 400,
         # height = 300,
         # alt = "This is alternate text"
    )}, deleteFile = TRUE)
}

shinyApp(ui = ui, server = server)

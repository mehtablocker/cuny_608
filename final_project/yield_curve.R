library(plyr)
library(tidyverse)
library(gganimate)
library(rvest)

### Establish start and end points
start_date <- as.Date("2018-10-16")
end_date <- as.Date(Sys.Date())
daily_monthly <- "monthly"

### Retrieve the data and filter it correctly
if (start_date>end_date){
  message("Start date must be before end date!")
} else{
  start_year <- as.numeric(format(start_date, "%Y"))
  end_year <- as.numeric(format(end_date, "%Y"))
  rates_df_raw <- data.frame()
  for (i in start_year:end_year){
    base_url <- "https://www.treasury.gov/resource-center/data-chart-center/interest-rates/Pages/TextView.aspx?data=yieldYear&year="
    full_url <- paste0(base_url, i)
    url_html <- full_url %>% read_html()
    table_list <- url_html %>% html_table(fill=T)
    rates_df_raw <- rbind.fill(rates_df_raw, table_list[[2]])
  }
  rates_df_raw <- rates_df_raw %>% mutate(Date=as.Date(Date, format="%m/%d/%y"))
  rates_df_raw <- suppressWarnings(rates_df_raw %>% mutate_at(vars(-Date), as.numeric))
  rates_df_filt <- rates_df_raw %>% filter(Date>=start_date, Date<=end_date)
  if (daily_monthly=="monthly"){
    rates_df_filt <- rates_df_filt %>% mutate(day_of_mth=format(Date, "%d")) %>% 
      filter(day_of_mth==format(max(Date), "%d")) %>% select(-day_of_mth)
  }
  rates_df <- rates_df_filt %>% gather(Term, value, 2:ncol(rates_df_raw), factor_key=T) %>% spread(Date, value)
  # rates_df %>% ggplot(aes(x=Term)) + geom_point(aes(y=!!sym(colnames(rates_df)[2]))) + 
  #   geom_line(aes(y=!!sym(colnames(rates_df)[2]), group=1, color=colnames(rates_df)[2])) + 
  #   geom_point(aes(y=!!sym(colnames(rates_df)[3]))) + 
  #   geom_line(aes(y=!!sym(colnames(rates_df)[3]), group=2, color=colnames(rates_df)[3])) + 
  #   labs(title="US Treasury Yield Curve", x="Term", y="Interest Rate", colour="")
  rates_df_long <- rates_df %>% 
    gather(Date, Rate, -Term) %>% 
    mutate(Date=as.Date(Date),
           Day_Number=as.numeric(Date-min(Date))+1)
  
  ### Make the plot and animate it
  p1 <- ggplot(rates_df_long, aes(x = Term, y = Rate))+
    geom_col() +
    labs(title = 'YIELD CURVE \n Date: {frame_time}', x = 'Term', y = 'Rate')+
    transition_time(Date)
  f_p_s <- round(nrow(rates_df_filt)/2.5)
  dur <- round(f_p_s*1.5)
  e_p <- round(dur*3)
  #animate(p1, fps = f_p_s, duration = dur, end_pause = e_p)
  animate(p1, fps = 10, duration = 15, end_pause = 45)
}

### Now next step is to make this code more general and turn it into a web app where the user can choose the options with clickable menus
Final Project Proposal
================

## Use the United States Department of the Treasury’s interest rates to build a web application

#### Intro

When I was a trader, an important piece of information was the current
state of US interest rates across different maturities, known as the
“Yield Curve.” While viewing the current yield curve is simple,
visualizing the yield curve across time is more complex, yet potentially
very interesting and valuable. Changes in the yield curve are known to
often be a gauge of what is happening in our economy.

For my final project I will build and deploy a web application that
allows the user to choose a time period and output a visualization that
shows the yield curve changing over that time period.

#### Data

The data is publicly available through the government at this
link:

<https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/textview.aspx?data=yield>

There are some interesting challenges to navigate, including the various
different formats available for the data, as well as the server side
loading times associated with the size of chosen time periods.
Efficiently handling these issues will be crucial to the performance of
the app.

#### Technology

I will build this app in R Shiny. I will also use ggplot, potentially
with the gganimate functionality, to create a graphic with motion.
Pulling the data itself may also require other R packages, depending on
the ultimate architecture.

I will deploy the finished app to a web server and also provide a link
to all of the R code, annotated to explain each step of the process.

My hope is that this app will actually provide a useful tool to both
myself and my friends in the financial industry.

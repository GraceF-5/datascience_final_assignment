#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#


# Load all libraries ------------------------------------------------------------------------
library(shiny)
library(shinythemes)
library(tidyverse)
library(colourpicker)

source("covid_data_load.R") ## This line runs the Rscript "covid_data_load.R", which is expected to be in the same directory as this shiny app file!
# The variables defined in `covid_data_load.R` are how fully accessible in this shiny app script!!

# UI --------------------------------
ui <- shinyUI(
        navbarPage( theme = shinytheme("superhero"), 
                   title = "COVID-19 Cases and Deaths", ### Replace title with something reasonable
            
            ## All UI for NYT goes in here:
            tabPanel("NYT data visualization", ## do not change this name
            
                    # All user-provided input for NYT goes in here:
                    sidebarPanel(
                        
                        colourpicker::colourInput("nyt_color_cases", "Color for plotting COVID cases:", value = "#59CFE6"),
                        colourpicker::colourInput("nyt_color_deaths", "Color for plotting COVID deaths:", value = "#AE1BB8"), 
                        selectInput("which_state",  ##input$which_state
                                    "Which state would you like to plot?", 
                                    choices = usa_states, 
                                    selected = "New Jersey"),
                        radioButtons("facet_county",
                                     "Show counties across panels, or pool all counties?",
                                     choices = c("Pool all counties", "Show counties across panels"),
                                     selected = "Pool all counties"),
                        radioButtons("y_scale",
                                     "Scale for Y-axis?",
                                     choices = c("Linear", "Log"),
                                     selected = "Linear"),
                        selectInput("which_theme",
                                    "Which ggplot theme to use?",
                                    choices = c("Classic", "Minimal", "Light", "Gray","Linedraw", "Dark"),
                                    selected = "Linedraw")
                        
                    ), # closes NYT sidebarPanel. Note: we DO need a comma here, since the next line opens a new function     
                    
                    # All output for NYT goes in here:
                    mainPanel(
                        plotOutput("nyt_plot")
                    ) # closes NYT mainPanel. Note: we DO NOT use a comma here, since the next line closes a previous function  
            ), # closes tabPanel for NYT data
            
            
            ## All UI for JHU goes in here:
            tabPanel("JHU data visualization", ## do not change this name
                     
                     # All user-provided input for JHU goes in here:
                     sidebarPanel(

                         colourpicker::colourInput("jhu_color_cases", "Color for plotting COVID cases:", value = "#F21FE7"),
                         colourpicker::colourInput("jhu_color_deaths", "Color for plotting COVID deaths:", value = "#00FFC4"),
                         selectInput("which_Country_or_Region",  ##input$which_Country_or_Region
                                     "Which Country or Region would you like to plot?", 
                                     choices = world_countries_regions, 
                                     selected = "US"), 
                         radioButtons("y_scale_jhu",
                                      "Scale for Y-axis?",
                                      choices = c("Linear", "Log"),
                                      selected = "Linear"),
                         selectInput("which_theme_jhu",
                                     "Which ggplot theme to use?",
                                     choices = c("Classic", "Minimal", "Light", "Gray","Linedraw", "Dark"),
                                     selected = "Linedraw")
                         
                         
                     ), # closes JHU sidebarPanel     
                     
                     # All output for JHU goes in here:
                     mainPanel(
                        plotOutput("jhu_plot")
                     ) # closes JHU mainPanel     
            ) # closes tabPanel for JHU data
    ) # closes navbarPage
) # closes shinyUI

# Server --------------------------------
server <- function(input, output, session) {

    ## PROTIP!! Don't forget, all reactives and outputs are enclosed in ({}). Not just parantheses or curly braces, but BOTH! Parentheses on the outside.
    
    ## All server logic for NYT goes here ------------------------------------------
    
    ## Define a reactive for subsetting the NYT data
    nyt_data_subset <- reactive({
        nyt_data %>%
            filter(state == input$which_state) -> nyt_state
        
            if (input$facet_county == "Pool all counties"){
                ##combine county data to get single point per day for case/death
                nyt_state %>%
                    group_by(date, covid_type)%>%
                    summarize(y = sum(cumulative_number)) -> final_nyt_state
            }
        if (input$facet_county == "Show counties across panels"){
            nyt_state %>%
                rename(y = cumulative_number) -> final_nyt_state
            
        }
        final_nyt_state
    })
    
    ## Define your renderPlot({}) for NYT panel that plots the reactive variable. ALL PLOTTING logic goes here.
    output$nyt_plot <- renderPlot({
        nyt_data_subset() %>%
            ggplot(aes(x = date, y = y, color = covid_type, group = covid_type))+
            geom_point()+
            geom_line()+
            scale_color_manual(values = c(input$nyt_color_cases, input$nyt_color_deaths)) +
            labs(title = paste(input$which_state, "Cases and Deaths"), y = "Cumulative Count", x = "Date")+
            guides(col = guide_legend("Covid Type")) -> my_nyt_plot
        
        ##Input$y_scale choices
        if(input$y_scale == "Log")my_nyt_plot <- my_nyt_plot + scale_y_log10()
        
        ##Deal with input$facet_county
        if(input$facet_county == "Yes") myplot <- my_nyt_plot + facet_wrap(~county, scales = "free_y")
        
        ##with input$which_theme choices
        if (input$which_theme == "Classic") my_nyt_plot <- my_nyt_plot + theme_classic()
        if (input$which_theme == "Minimal") my_nyt_plot <- my_nyt_plot + theme_minimal()
        if (input$which_theme == "Light") my_nyt_plot <- my_nyt_plot + theme_light()
        if (input$which_theme == "Gray") my_nyt_plot <- my_nyt_plot + theme_gray()
        if (input$which_theme == "Linedraw") my_nyt_plot <- my_nyt_plot + theme_linedraw()
        if (input$which_theme == "Dark") my_nyt_plot <- my_nyt_plot + theme_dark()

        ##return to the plot
        my_nyt_plot + theme(legend.position = "right")})
  
    
    ## All server logic for JHU goes here ------------------------------------------
    ## Define a reactive for subsetting the JHU data
    jhu_data_subset <- reactive({
      jhu_data %>%
        filter(Country_or_Region == input$which_Country_or_Region) -> jhu_country })
    
    ## Define your renderPlot({}) for JHU panel that plots the reactive variable. ALL PLOTTING logic goes here.
    output$jhu_plot <- renderPlot({
      jhu_data_subset() %>%
        ggplot(aes(x = Date, y = Cumulative_Number, color = Covid_Type, group = Covid_Type))+
        geom_point()+
        geom_line()+
        scale_color_manual(values = c(input$jhu_color_cases, input$jhu_color_deaths))-> my_jhu_plot
        
      
      ##Input$y_scale choices
      if(input$y_scale_jhu == "Log"){
        my_jhu_plot <- my_jhu_plot + scale_y_log10()
      }
      
      ##with input$which_theme choices
      if (input$which_theme_jhu == "Classic") my_jhu_plot <- my_jhu_plot + theme_classic()
      if (input$which_theme_jhu == "Minimal") my_jhu_plot <- my_jhu_plot + theme_minimal()
      if (input$which_theme_jhu == "Light") my_jhu_plot <- my_jhu_plot + theme_light()
      if (input$which_theme_jhu == "Gray") my_jhu_plot <- my_jhu_plot + theme_gray()
      if (input$which_theme_jhu == "Linedraw") my_jhu_plot <- my_jhu_plot + theme_linedraw()
      if (input$which_theme_jhu == "Dark") my_jhu_plot <- my_jhu_plot + theme_dark()
        
        ##return to the plot
        my_jhu_plot + theme(legend.position = "right")+
        theme(axis.text.x = element_text(angle = 60))+
        labs(title = paste(input$which_Country_or_Region, "Cases and Deaths", x = "Date", y = "Cumulative Number"))+
        guides(col = guide_legend("Covid Type"))
        })
    
}

# Do not touch below this line! ----------------------------------
shinyApp(ui = ui, server = server)

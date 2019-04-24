library(shiny)
library(rhandsontable)
library(readr)


ui <- navbarPage(

  theme = "https://bootswatch.com/3/spacelab/bootstrap.min.css",
  inverse = TRUE,
  title = "Create Meta Data Table",


  column(12,
         column(3,
                conditionalPanel("!output.tableCreated",
                  h4(strong("Create New Table")),
                  wellPanel(
                    textAreaInput("samplesList", "List of Sample names", width = "100%", rows = 5),
                    h4(strong("Or")),
                    fileInput('datafile', 'Upload sample names file (.csv, .txt)',
                              accept=c('text/csv', 
                                       'text/comma-separated-values,text/plain', 
                                       '.csv,.txt'),multiple = F
                    ),
                    #numericInput("numSamples","Number of Samples", min = 1,value = 12),
                    #textInput("groupnames","group conditions (comma seperated)",placeholder = "Eg. MT, WT"),
                    actionButton("createTable","Create Table", class = "btn btn-primary")
                  )
                )
                ,
                conditionalPanel("output.tableCreated",
                                 h4("Add Conditions/Factors"),
                                 wellPanel(
                                   textInput("conditionName","Condition/Factor Name", placeholder = "Eg. Time"),
                                   textInput("conditions","List of Conditions/Factors (comma seperated)",placeholder = "Eg. 1hr, 5hr, 6hr"),
                                   actionButton("addConditions","Add Condition/Factor", class = "btn btn-primary")
                                 ),
                                 hr(),
                                 h4("Remove Columns"),
                                 wellPanel(
                                   selectInput("colToRemove", "Remove Column", choices = NULL),
                                   actionButton("removeCol","Remove", class = "btn btn-danger", icon = icon("times"))
                                 )
                )
                ),
         column(9,
                conditionalPanel("output.tableCreated",
                                 h4("Edit Table"),
                                 tags$ul(
                                   tags$li("Rename Samples"),
                                   tags$li("Tag samples with corresponding conditions"),
                                   tags$li("Download CSV")
                                 ),
                                 downloadButton('downloadCSV','Download CSV'),
                                 hr(),
                                 rHandsontableOutput("table")
                )

         )
         )



)


server <- function(input, output,session) {

  myValues <- reactiveValues()

  observe({
    tableCreateReactive()
  })

  tableCreateReactive <- reactive({

    if(input$createTable > 0)
    {
      isolate({
        
        
        validate(
          
          need((input$samplesList!="")|(!is.null(input$datafile)),
               message = "Please select a file or type in list of sample names")
        )
        
        
        if(input$samplesList!="")
          inputSampleNames = input$samplesList
        else
          inputSampleNames <- read_file(input$datafile$datapath)
        
        samplenames = getSampleNamesFromStr(inputSampleNames)
        
        DF = data.frame(Samples=samplenames)


        myValues$DF = DF
        myValues$conditions = list()
      })
    }
  })


  observe({

    colnamesChoices = colnames(myValues$DF[!(names(myValues$DF) %in% c("Samples","Groups"))])
    updateSelectInput(session, "colToRemove", choices = colnamesChoices, selected = NULL)

  })

  observeEvent(input$removeCol,{
    validate(
      need(input$colToRemove != "", message = "need to select column to remove")
    )
    myValues$DF[,input$colToRemove] = NULL
  })

  observe({
    tableEditReactive()
  })

  tableEditReactive <- reactive({

    if(input$addConditions > 0)
    {

      isolate({
        myValues$DF = hot_to_r(input$table)
        DF = myValues$DF


        validate(
          need(!(input$conditionName %in% colnames(DF)), message = "Condition name already exists"),
          need(trimws(input$conditionName) != "", message = "Condition name empty"),
          need(trimws(input$conditions) != "", message = "Conditions empty")
        )

        newDF = data.frame(newCol = character(dim(DF)[1]))
        names(newDF) = c(input$conditionName)

        DF = cbind(DF,newDF)

        myValues$DF = DF

        myValues$conditions[[dim(DF)[2] - 1]] = input$conditions

        updateTextInput(session, "conditionName", value = "")
        updateTextInput(session, "conditions",value = "")

      })
    }
  })

  output$tableCreated <-
    reactive({
      return(!is.null(myValues$DF))
    })
  outputOptions(output, 'tableCreated', suspendWhenHidden=FALSE)

  output$table = renderRHandsontable({

    DF1 = myValues$DF
    if(is.null(DF1))
      return()


    table = rhandsontable(DF1)  %>%
      hot_cols(colWidths = 100)

    table =  table %>% hot_table(highlightCol = TRUE, highlightRow = TRUE, colHeaders = NULL)

    for(i in 2:dim(DF1)[2])
    {
      if(dim(DF1)[2] < 2)
        break()
      if(!is.null(myValues$conditions[[i-1]]))
        table = table %>% hot_col(col = colnames(DF1)[i], type = "dropdown", source = getConditionsListFromStr(myValues$conditions[[i-1]]))

    }

        table

  })

  output$downloadCSV <- downloadHandler(

    filename = paste0("metadatatable_",format(Sys.time(), "%y-%m-%d_%H-%M-%S"),".csv"),
    content = function(file) {
      write.csv(hot_to_r(input$table), file, row.names=F)
      }
  )

}

getConditionsListFromStr <- function(conditonsStr)
{
  conditions =isolate(  unlist(strsplit(conditonsStr,",")) )
  conditions = trimws(conditions)
  conditions = conditions[conditions != ""]
  conditions = unique(conditions)
  return(conditions)
}

getSampleNamesFromStr <- function(samplenamesStr)
{
  samplenames = unlist(strsplit(samplenamesStr,","))
  samplenames = unlist(strsplit(samplenames,"\n"))
  samplenames = unlist(strsplit(samplenames,"\t"))
  samplenames = unlist(strsplit(samplenames," "))
  
  samplenames = trimws(samplenames)
  samplenames = samplenames[samplenames != ""]
  samplenames = unique(samplenames)
  
  return(samplenames)
}

shinyApp(ui = ui, server = server)

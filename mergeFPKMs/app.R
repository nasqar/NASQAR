library(shiny)
library(parallel)


# User Interface stuff
ui <- tagList(
  tags$head(
    tags$style(HTML(" .shiny-output-error-validation {color: darkred; } ")),
    tags$style(".mybuttonclass{background-color:#CD0000;} .mybuttonclass{color: #fff;} .mybuttonclass{border-color: #9E0000;}")
  ),
  navbarPage(
    
    theme = "https://bootswatch.com/3/spacelab/bootstrap.min.css",
    inverse = TRUE,
    title = "Merge FPKM Files",
    tabPanel("", 
             fluidRow(column(4,wellPanel(
               h4("Upload all FPKM files"),
               h4("(select at least 2 csv files)"),
               fileInput('datafile', '',
                         accept=c('text/csv', 
                                  'text/comma-separated-values,text/plain', 
                                  '.csv'),multiple = TRUE
               ),
               #checkboxInput("addOne", "Add +1 to counts (pseudo counts)", FALSE),
               checkboxInput("fpkmToTpm", "Convert to TPMs", FALSE),
               checkboxInput("addGeneNames", "Retrieve gene names from ensembl ids", FALSE),
               conditionalPanel("input.addGeneNames",
                                radioButtons('refGenome','',
                                             c('Homo_sapiens.GRCh38.81',
                                               'Homo_sapiens.GRCh38.84',
                                               'Mus_musculus.GRCm38.82',
                                               'Danio_rerio.GRCz10.84',
                                               'Drosophila_melanogaster.BDGP6.81'
                                             ),selected = "Homo_sapiens.GRCh38.81"),
                                radioButtons('geneNameColumn','',
                                             c('Add gene.names column after gene ids'="add",
                                               'Replace gene ids column by gene names'="replace"
                                             ),selected = "add")),
               conditionalPanel("output.filesUploaded",
                                actionButton("upload_data","Merge Files",
                                             style="color: #fff; background-color: #CD0000; border-color: #9E0000")),
               conditionalPanel("output.filesMerged",
                                downloadLink('downloadData', 'Download Merged File',class = "btn btn-primary", style="color: #fff; background-color: #9E0000; border-color: #9E0000"))
             )
             ),#column
             column(8,
                    conditionalPanel("output.filesMerged",
                                     h2("Merged Table"),
                                     hr(),
                                     dataTableOutput("contents")
                                     ),
                    conditionalPanel("!output.filesMerged",
                                     h2("User Guide"),
                                     hr(),
                                     h4(strong("1) Introduction:")),
                                     wellPanel(
                                       
                                       p("This is a simple preprocessing tool to merge individual gene FPKM files (Eg. fpkm files from cufflinks)"),
                                       p(strong("NOTE:"),"first column must contain the genes. If the gene columns do not match in all files, this tool will not work"),
                                       hr(),
                                       h5(strong("Features")),
                                       tags$ul(
                                         tags$li("Merge individual gene FPKM files. See ",strong("Sample Input Files")," below for more details"),
                                         tags$li("Or merge", strong(" multiple matrices")),
                                         tags$li(strong("Convert ensembl gene IDs to gene names"),
                                                 tags$ul(
                                                   tags$li("Option to choose from available genome/versions")
                                                   
                                                 )
                                         ), 
                                         tags$li("Option to convert FPKMs to ", strong("TPMs")),
                                         tags$li(strong("Download")," merged FPKMs file in .csv format")
                                       )
                                     ),
                                     hr(),
                                     #wellPanel(
                                     h4(strong("2) Sample Input Files:")),
                                     tags$div(class = "BoxArea2",
                                              fluidRow(
                                                column(12,
                                                       p(strong("Select multiple files to upload, E.g. Input files:")),
                                                       column(5,
                                                              p(strong(tags$em("File 1 of 8: ")), "Sample_S2L_gene_fpkms.txt"),
                                                              tags$img(src = "inputFiles.png", width = "400px", height = "100px")),
                                                       column(5,
                                                              p(strong(tags$em("File 2 of 8: ")), "Sample_S2V_gene_fpkms.txt"),
                                                              tags$img(src = "inputFiles.png", width = "400px", height = "100px")),
                                                       column(2,
                                                              p(strong("etc ...")))
                                                       
                                                ),
                                                div(style = "clear:both;")
                                              ),
                                              
                                              fluidRow(
                                                column(12,
                                                       p(""),
                                                       p(strong("Note: "),'File names will be used as sample (column) names in output table. You can edit the column names after merging'))
                                              )
                                              
                                     ),
                                     column(12,hr()),
                                     h4(strong("3) Sample Output File:")),
                                     div(style = "clear:both;"),
                                     tags$div(class = "BoxArea2",
                                              p(strong("Output depending on options selected:")),
                                              column(12,
                                                     p(strong(em("A) Without renaming/converting genes (Default)"))),
                                                     tags$img(src = "output_geneids.png", width = "400px", height = "100px")),
                                              column(12,
                                                     hr()),
                                              column(6,
                                                     p(strong(em("B) Retrieve gene names (replace), E.g. output file"))),
                                                     tags$img(src = "output_genenames.png", width = "400px", height = "100px")),
                                              column(6,
                                                     p(strong(em("C) Retrieve gene names (add), E.g. output file"))),
                                                     tags$img(src = "output_both.png", width = "400px", height = "100px")),
                                              div(style = "clear:both;")
                                     )
                                     
                                     
                    )
                    
             )#column
             )#fluidrow
    ),#tabpanel
    
    
    
    ## ==================================================================================== ##
    ## FOOTER
    ## ==================================================================================== ##              
    footer=p(hr(),p("mergeFPKMs developed by ", strong("Bioinformatics Core")," ",align="center",width=4),
             p(("Center for Genomics and Systems Biology, NYU Abu Dhabi"),align="center",width=4),
             p(strong("Acknowledgements:") , " Nathalie Neriec",align="center",width=4),
             p(("Copyright (C) 2018, code licensed under GPLv3"),align="center",width=4)
    )
  ) #end navbarpage
) #end taglist



# Max upload size
options(shiny.maxRequestSize = 600*1024^2)
# Define server 
server <- function(input, output,session) {
  
  output$contents <- renderDataTable({
    tmp <- dataReactive()
    if(!is.null(tmp)) tmp$data
  })
  
  output$filesMerged <- reactive({
    return(!is.null(dataReactive()))
  })
  outputOptions(output, 'filesMerged', suspendWhenHidden=FALSE)
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste('merged-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(dataReactive()$data, con,row.names=FALSE)
    }
  )
  
  inputDataReactive <- reactive({
    
    inFile <- input$datafile
    if (is.null(inFile))
      return(NULL)
    
    
    return(inFile)
  })
  
  
  dataReactive <- 
    eventReactive(input$upload_data,
                  ignoreNULL = FALSE, {
                    
                    inFile <- inputDataReactive()
                    if(is.null(inFile))
                      return(NULL)
                    
                    progress <- Progress$new(session, min=0, max=1)
                    on.exit(progress$close())
                    
                    progress$set(message = 'Merging files ...')
                    
                    files <- list();
                    
                    
                    # select file separator, either tab or comma
                    sep = '\t'
                    if(length(inFile$datapath) > 0 ){
                      testSep = read.csv(inFile$datapath[1], header = TRUE, sep = '\t')
                      if(ncol(testSep) < 2)
                        sep = ','
                    }
                    else
                      return(NULL)
                    
                    #remove zero size files
                    inFile <- inFile[inFile$size != 0,]
                    
                    
                    fileContent = read.csv(inFile$datapath[1], header = TRUE, sep = sep)
                    #fileContent = fileContent[!grepl("__", fileContent$V1),] #remove rows containing underscores
                    
                    
                    ######################
                    
                    
                    #Remove all columns except gene_id and FPKM
                    fileContent = fileContent[,colnames(fileContent) %in% c("gene_id","FPKM")]
                    
                    #Sort by gene_id incase they are not sorted
                    fileContent = fileContent[order(fileContent$gene_id),]
                    
                    #Create data frame table
                    total = data.frame(matrix(ncol = length(inFile) + 1, nrow = nrow(fileContent)))
                    
                    #Extract sample name from file name
                    samplename = tools::file_path_sans_ext(inFile$name[1])
                    
                    
                    #Create first column "gene.ids", and second column for first sample FPKMS
                    total[,1] = fileContent$gene_id
                    total[,2] = fileContent$FPKM
                    
                    # convert to TPMs if selected
                    if(input$fpkmToTpm)
                      total[,2] = FPKM_to_TPM(fileContent$FPKM)
                    else
                      total[,2] = fileContent$FPKM
                    
                    #Set Column names
                    colnames(total)[1] = "gene.ids"
                    colnames(total)[2] = samplename
                    
                    
                    #Add the rest of the sample files FPKMs to data frame table
                    for (i in 2:length(inFile$datapath))
                    {
                      
                      if(length(inFile$datapath) == 1)
                        break
                      
                      fileContent = read.csv(inFile$datapath[i], header = TRUE, sep = "\t")
                      
                      #Remove all columns except gene_id and FPKM
                      fileContent = fileContent[,colnames(fileContent) %in% c("gene_id","FPKM")]
                      
                      #Sort by gene_id incase they are not sorted
                      fileContent = fileContent[order(fileContent$gene_id),]
                      
                      #extract file name
                      samplename = tools::file_path_sans_ext(inFile$name[i])
                      
                      #samplename = gsub("_gene_fpkms","",samplename)
                      
                      # if checkbox is checked, convert to TPMs
                      if(input$fpkmToTpm)
                      {
                        total[,i+1] = FPKM_to_TPM(fileContent$FPKM)
                      
                        }
                      else
                        total[,i+1] = fileContent$FPKM
                      
                      #Set the column names to the file names they came from
                      colnames(total)[i+1] = samplename
                      
                      #increase progress bar
                      progress$set(value = i/length(inFile$datapath))
                      
                    }
                    
                    
                    ######################
                    
                    
                    if(input$addGeneNames)
                    {
                      geneNames <- getNamesFromEnsembl(total$gene.ids, progress)
                      
                      if(input$geneNameColumn == "add")
                        total = as.data.frame(append(total, list(gene.names= geneNames), after = 1))
                      else{
                        
                        total[,1] = make.names(geneNames, unique=TRUE)
                        colnames(total)[1] = "gene.names"
                      }
                        
                    }
                    
                    # if(input$addOne)
                    #   total[,!(names(total) %in% c("gene.ids","gene.names"))] = total[,!(names(total) %in% c("gene.ids","gene.names"))] + 1
                    # 
                    
                    
                    return(list('data'=total))
                    
                  })
  
  # function to get gene names from ids based on gtf files for reference genome
  getNamesFromEnsembl <- function(ensNames, progress)
  {
    progress$set(value = 0.3)
    progress$set(message = 'Adding gene names ...')
    
    
    if(input$refGenome == "Homo_sapiens.GRCh38.81")
      load("Homo_sapiens.GRCh38.81.Rda")
    else if(input$refGenome == "Homo_sapiens.GRCh38.84")
      load("Homo_sapiens.GRCh38.84.Rda")
    else if(input$refGenome == "Mus_musculus.GRCm38.82")
      load("Mus_musculus.GRCm38.82.Rda")
    else if(input$refGenome == "Danio_rerio.GRCz10.84")
      load("Danio_rerio.GRCz10.84.Rda")
    else if(input$refGenome == "Drosophila_melanogaster.BDGP6.81")
      load("Drosophila_melanogaster.BDGP6.81.Rda")
    
    
    # using clusters to make it faster
    
    # Calculate the number of cores
    no_cores <- detectCores() - 1
    
    # Initiate cluster
    cl <- makeCluster(no_cores)
    
    print(paste(format(Sys.time(), "%H:%M:%OS3"),": Started Renaming ",length(ensNames), " genes"))
    
    levelsList = parallel::parLapply(cl,ensNames, function(x){
      return(geneid2name[geneid2name$gene_id == as.character(x),]$gene_name)
    })

    
    print(paste(format(Sys.time(), "%H:%M:%OS3"),": Finished renaming"))
    stopCluster(cl)
    
    
    progress$set(value = 0.8)
    
    flatList = unlist(levelsList)
    
    progress$set(value = 1)
    return(flatList)
    
  }
  
  #Function to convert FPKMs to TPMs
  FPKM_to_TPM <- function(FPKMCol){
    
    # CALCULATE SUM(FPKM)
    Total_FPKMS<- sum(FPKMCol)
    #Divide Total FPKM by 10^6 (so dont have to multiple everythin by 10^6)
    Total_FPKMS_divided<-Total_FPKMS/1000000
    # process for each Row from FPKM to TPM
    TPMCol<-FPKMCol/Total_FPKMS_divided
    
    return(TPMCol)
  }
  
  
  output$filesUploaded <- reactive({
    return(!is.null(inputDataReactive()))
  })
  outputOptions(output, 'filesUploaded', suspendWhenHidden=FALSE)
  
  output$filesMerged <- reactive({
    return(!is.null(dataReactive()))
  })
  outputOptions(output, 'filesMerged', suspendWhenHidden=FALSE)
  
  
}

shinyApp(ui = ui, server = server)

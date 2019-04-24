tabPanel("Getting Started",
         fluidRow(
           #h4("Other tools/utilities:"),
           #column(6,tags$a(target="_blank",class = "button button-3d button-default button-block button-rounded button-large", href = "http://tsar.abudhabi.nyu.edu:8066","Merge Count files")),
           #column(6,tags$a(target="_blank",class = "button button-3d button-default button-block button-rounded button-large", href = "http://tsar.abudhabi.nyu.edu:8067","Single Cell Analysis")),
           #column(12,hr()),
           column(4,wellPanel(
             h4("Getting Started with START"),
             a("Features", href="#features"),br(),
             a("Data Formats", href = "#dataformats"), br(),
             a("Save Data for Future Upload", href="#savedata"), br(),
             a("More Help", href = "#help"), br()
           )
           ),#column
           column(8,
                  includeMarkdown("instructions/landing.md"))
         ))

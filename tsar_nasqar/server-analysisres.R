## ==================================================================================== ##
# START Shiny App for analysis and visualization of transcriptome data.
# Copyright (C) 2016  Jessica Minnier
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# You may contact the author of this code, Jessica Minnier, at <minnier@ohsu.edu>
## ==================================================================================== ##
## 
## 
## #update list of groups
observe({
  
  print("server-analysisres-update")
  
  data_analyzed = analyzeDataReactive()
  tmpdat = data_analyzed$results
  tmpgroups = data_analyzed$group_names
  tmptests = unique(as.character(tmpdat$test))
  tmptests_ma = c("All",tmptests)
  tmpdatlong = data_analyzed$data_long
  tmpynames = tmpdatlong%>%select(-unique_id,-sampleid,-group)%>%colnames()
  
  updateSelectizeInput(session,'analysisres_test',
                       choices=tmptests, selected=tmptests[1])
  
  updateSelectizeInput(session,'analysisres_groups',
                       choices=tmpgroups)
  if(length(tmpgroups)==2) {
    updateSelectizeInput(session,'analysisres_groups',
                         choices=tmpgroups,selected = tmpgroups)
  }
  
  updateRadioButtons(session,'scattervaluename',
                     choices=sort(tmpynames,decreasing = TRUE))
  
  updateSelectizeInput(session,'analysisres_test_ma',
                       choices=tmptests_ma, selected=tmptests_ma[1])
  
  
})






observe({
  
  print("drawing volcano plot")
  
  data_analyzed = analyzeDataReactive()
  data_results = data_analyzed$results
  geneids = data_analyzed$geneids
  
  output$volcanoplot <- renderPlotly({
    validate(need(input$analysisres_test!="","Select a test."))
    validate(need(data_results%>%filter(test==input$analysisres_test)%>%nrow()>0,"Test not found."))
    
    withProgress(message = "Drawing volcano plot, please wait",
                 {
                   # rna_volcanoplot(data_results = data_results,
                   #                 test_sel = input$analysisres_test,
                   #                 absFCcut = input$analysisres_fold_change_cut,
                   #                 fdrcut = input$analysisres_fdrcut)%>%
                   #   bind_shiny("volcanoplot_2groups_ggvis","volcanoplot_2groups_ggvisUI")
                   if (names(dev.cur()) != "null device") dev.off()
                   pdf(NULL)
                   p=rna_volcanoplot(data_results = data_results,
                                   test_sel = input$analysisres_test,
                                   absFCcut = input$analysisres_fold_change_cut,
                                   fdrcut = input$analysisres_fdrcut)
                   
                 })#end withProgress
    
  }) 
})



observe({
  
  print("drawing scatterplot")
  
  #if(length(input$analysisres_groups)==2) {
  data_analyzed = analyzeDataReactive()
  data_long = data_analyzed$data_long
  geneids = data_analyzed$geneids
  
  
  
  # rna_scatterplot(data_long = data_long,
  #                 group_sel = input$analysisres_groups,
  #                 valuename=input$scattervaluename)%>%
  #   bind_shiny("scatterplot_fc_2groups_ggvis","scatterplot_fc_2groups_ggvisUI")
  output$scatterplot <- renderPlotly({ 
    validate(need(length(input$analysisres_groups)==2,"Please select two groups."))
    withProgress(message = "Drawing scatterplot, please wait",{
      if (names(dev.cur()) != "null device") dev.off()
      pdf(NULL)
      p=rna_scatterplot(data_long = data_long,
                      group_sel = input$analysisres_groups,
                      valuename=input$scattervaluename)
    })#end withProgress
  })
  
  
  
  #}
})
library(DESeq2)
observe({
  
  print("drawing MA volcano plot - deseq")

  data_analyzed = analyzeDataReactive()
  data_results = data_analyzed$results

  dds <- data_analyzed$dds
  res <- results(dds)
  ymax <- input$analysisres_ma_plot_ylim

  
  # this object will be used to locate points from click events.
  data <- with(res, cbind(baseMean, log2FoldChange))
  data[,2] <- pmin(ymax, pmax(-ymax, data[,2]))
  scale <- c(diff(range(data[,1])), 2*ymax)
  t.data.scaled <- t(data)/scale
  
  
  #######
  
  
  current = reactiveValues(idx = NULL)
  
  observeEvent(input$analysisres_test_ma, {
    current$idx = NULL
  })
  
  observe({
    xy = c(input$plotma_click$x, input$plotma_click$y)
    if (!is.null(xy)) {
      ## find index of the closest point
      sqdists <- colMeans( (t.data.scaled - xy/scale )^2 )
      current$idx <- which.min(sqdists)
    }
  })
  
  
  # MA-plot
  output$plotma <- renderPlot({
    #par( mar=c(5,5,3,2), cex.main=1.5, cex.lab=1.35 )
    test <- as.data.frame(data_analyzed$data_results_table)
    
    logicVar <- logical(length = nrow(test)) == FALSE
    
    
    validate(need(input$analysisres_test_ma!="","Select a test."))
    validate(need(data_results%>%filter(test==input$analysisres_test_ma)%>%nrow()>0 || input$analysisres_test_ma == "All","Test not found."))
    
    if(input$analysisres_test_ma == "All")
    {
      res = results(dds)
    }
    else
    {
      groups = unlist(strsplit(input$analysisres_test_ma,"/"))
      contrast=c("condition",groups[1],groups[2])
      res = results(dds,contrast = contrast)
    }
    
    plotMA( res, ylim=c(-ymax, ymax) , alpha=input$alpha )
    # add a circle around the selected point
    idx = current$idx
    if (!is.null(idx)) points( data[idx,1], data[idx,2], col="dodgerblue", cex=3, lwd=3 )
  })
  
  
  # counts plot for the selected gene
  output$plotcounts <- renderPlot({
    par( mar=c(5,5,3,2), cex.main=1.5, cex.lab=1.35 )
    # update only when idx changes
    idx = current$idx
    print(idx)
    if (!is.null(idx)) plotCounts( data_analyzed$dds, idx )
  })
  
})






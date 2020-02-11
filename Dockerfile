# Install R version 3.5
#FROM r-base:3.5.0
#FROM r-base:3.6.2
FROM rocker/shiny:3.6.1

# Install Ubuntu packages
RUN apt-get update && apt-get install -y \
    sudo \
    libssl-dev

# Switching to rocker so we don't need this
# Download and install ShinyServer (latest version)
#RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
#    VERSION=$(cat version.txt)  && \
#    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
#    gdebi -n ss-latest.deb && \
#    rm -f version.txt ss-latest.deb

# Install R packages that are required
# add packages for CountMerger
RUN R -e "install.packages(c('shiny', 'shinyBS', 'readr', 'shinyjs','sodium','uuid','markdown'), repos='http://cran.rstudio.com/')"


# add packages for deseq2
RUN R -e "install.packages(c('shinydashboard', 'shinycssloaders', 'DT', 'rhandsontable','RColorBrewer','pheatmap','ggplot2','ggthemes', 'plotly','NMF'), repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('BiocManager');  BiocManager::install('BiocParallel')"

RUN R -e "BiocManager::install(c('DESeq2'))"
#RUN R -e "install.packages('https://bioconductor.org/packages/3.6/bioc/src/contrib/Archive/DESeq2/DESeq2_1.18.0.tar.gz', repos = NULL, type='source')"
RUN R -e "install.packages('V8')"


# shinyngs
RUN R -e "BiocManager::install(c('SummarizedExperiment','GSEABase'))"
RUN R -e "install.packages('devtools')"
#RUN R -e "devtools::install_github('pinin4fjords/shinyngs', upgrade_dependencies = FALSE)"

#startapp
RUN R -e "BiocManager::install(c('limma','edgeR'))"
RUN R -e "install.packages(c('reshape2','gplots','ggvis','dplyr','tidyr','scales','heatmaply','ggrepel','colourpicker'), repos='http://cran.rstudio.com/')"

# shaman
RUN apt-get update && apt-get install -y libmagick++-dev
RUN R -e "source('https://raw.githubusercontent.com/aghozlane/shaman/master/LoadPackages.R')"

# download apps
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/yan-cri/DEApp/archive/master.zip', destfile = 'deapp.zip'); unzip(zipfile = 'deapp.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/GeneCountMerger/archive/master.zip', destfile = 'genecountmerger.zip'); unzip(zipfile = 'genecountmerger.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/aghozlane/shaman/archive/master.zip', destfile = 'shaman.zip'); unzip(zipfile = 'shaman.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/jminnier/STARTapp/archive/master.zip', destfile = 'startapp.zip'); unzip(zipfile = 'startapp.zip')"

# clusterprofiler apps
RUN R -e "BiocManager::install(c('clusterProfiler','DOSE','GOplot','enrichplot','pathview'))"
RUN R -e "BiocManager::install(c('org.Hs.eg.db','org.Mm.eg.db','org.Rn.eg.db','org.Sc.sgd.db','org.Dm.eg.db','org.At.tair.db','org.Dr.eg.db','org.Bt.eg.db','org.Ce.eg.db','org.Gg.eg.db','org.Cf.eg.db','org.Ss.eg.db','org.Mmu.eg.db','org.EcK12.eg.db','org.Xl.eg.db','org.Pt.eg.db','org.Ag.eg.db','org.Pf.plasmo.db','org.EcSakai.eg.db'))"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/ClusterProfShinyORA/archive/master.zip', destfile = 'clustora.zip'); unzip(zipfile = 'clustora.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/ClusterProfShinyGSEA/archive/master.zip', destfile = 'clustprofgsea.zip'); unzip(zipfile = 'clustprofgsea.zip')"
RUN R -e "install.packages('wordcloud2')"


# seuratwizard and seuratv3wizard
RUN apt-get update && apt-get install -y libhdf5-dev
RUN R -e "BiocManager::install(c('multtest'))"
RUN R -e "devtools::install_github('nasqar/SeuratWizard')"
#RUN R -e "devtools::install_version(package = 'Seurat', version = package_version('2.3.4'), upgrade='never',repos='https://cloud.r-project.org')"
RUN apt-get update && apt-get install -y libpython-dev python-pip
RUN R -e "source('https://z.umn.edu/archived-seurat')"
RUN R -e "devtools::install_github('nasqar/seuratv3wizard', upgrade_dependencies = FALSE,ref = 'nasqarfix',repos=NULL)"
RUN R -e "devtools::install_github(lib='/usr/local/lib/R/site-library/SeuratV3Wizard/shiny/SeuratLib',repo = 'satijalab/seurat', force=T)"
RUN R -e "devtools::install_github(repo = 'ChristophH/sctransform',repos=NULL)"
RUN pip install cellbrowser
RUN pip install umap-learn

# fix datatables issue by downgrading shiny and htmltools
RUN R -e "devtools::install_version('htmltools', version = '0.3.6', repos = 'http://cran.us.r-project.org')"
RUN R -e "devtools::install_version(package = 'shiny', version = package_version('1.3.2'),upgrade=F, repos='https://cran.r-project.org/', dependencies = T)"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/deseq2shiny/archive/master.zip', destfile = 'deseq2shiny.zip'); unzip(zipfile = 'deseq2shiny.zip')"

RUN R -e "install.packages('janitor')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/GeneCountMerger/archive/master.zip', destfile = 'genecountmerger.zip'); unzip(zipfile = 'genecountmerger.zip')"

# Copy configuration files into the Docker image
COPY docker_files/shiny-server.conf  /etc/shiny-server/shiny-server.conf
COPY . /srv/shiny-server
# Copy further configuration files into the Docker image
COPY docker_files/shiny-server.sh /usr/bin/shiny-server.sh
COPY docker_files/sitemap.xml /srv/shiny-server/
RUN R -e "devtools::install_github('andrewsali/shinycssloaders@0.2.0')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/ClusterProfShinyGSEA/archive/master.zip', destfile = 'clustprofgsea.zip'); unzip(zipfile = 'clustprofgsea.zip')"

RUN mv /tmp/DEApp-master /srv/shiny-server/DEApp
RUN mv /tmp/GeneCountMerger-master /srv/shiny-server/GeneCountMerger
RUN mv /tmp/deseq2shiny-master /srv/shiny-server/deseq2shiny
RUN mv /tmp/shaman-master /srv/shiny-server/shaman
RUN mv /tmp/STARTapp-master /srv/shiny-server/STARTapp
RUN mv /tmp/ClusterProfShinyGSEA-master /srv/shiny-server/ClusterProfShinyGSEA
RUN mv /tmp/ClusterProfShinyORA-master /srv/shiny-server/ClusterProfShinyORA

RUN sed -i '/options(repos = BiocInstaller::biocinstallRepos())/d' /srv/shiny-server/STARTapp/server.R
RUN chown -R shiny:shiny /srv/shiny-server
RUN chmod -R 777 /usr/local/lib/R/*/SeuratV3Wizard/shiny/www
RUN chmod -R 777 /srv/shiny-server/tsar_nasqar

#RUN usermod -aG sudo shiny

# Make the ShinyApp available at port 80
EXPOSE 80

#CMD ["/usr/bin/shiny-server.sh"]

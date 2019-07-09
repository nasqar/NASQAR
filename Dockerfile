# Install R version 3.5
FROM r-base:3.5.0

# Install Ubuntu packages
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev/unstable \
    libxt-dev \
    libssl-dev \
    libsodium-dev \
    libxml2-dev \
    libv8-3.14-dev

# Download and install ShinyServer (latest version)
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

# Install R packages that are required
# add packages for CountMerger
RUN R -e "install.packages(c('shiny', 'shinyBS', 'readr', 'shinyjs','sodium','uuid','markdown'), repos='http://cran.rstudio.com/')"


# add packages for deseq2
RUN R -e "install.packages(c('shinydashboard', 'shinycssloaders', 'DT', 'rhandsontable','RColorBrewer','pheatmap','ggplot2','ggthemes', 'plotly','NMF'), repos='http://cran.rstudio.com/')"
RUN R -e "source('https://bioconductor.org/biocLite.R'); biocLite('BiocParallel')"

RUN R -e "source('https://bioconductor.org/biocLite.R'); biocLite(c('DESeq2'))"
RUN R -e "install.packages('https://bioconductor.org/packages/3.6/bioc/src/contrib/Archive/DESeq2/DESeq2_1.18.0.tar.gz', repos = NULL, type='source')"
RUN R -e "install.packages('V8')"


# shinyngs
RUN R -e "source('https://bioconductor.org/biocLite.R'); biocLite(c('SummarizedExperiment','GSEABase'))"
RUN R -e "install.packages('devtools')"
#RUN R -e "devtools::install_github('pinin4fjords/shinyngs', upgrade_dependencies = FALSE)"

#startapp
RUN R -e "source('https://bioconductor.org/biocLite.R'); biocLite(c('limma','edgeR'))"
RUN R -e "install.packages(c('reshape2','gplots','ggvis','dplyr','tidyr','scales','heatmaply','ggrepel','colourpicker'), repos='http://cran.rstudio.com/')"

# shaman
RUN apt-get update && apt-get install -y libmagick++-dev
RUN R -e "source('https://raw.githubusercontent.com/aghozlane/shaman/master/LoadPackages.R')"

# seuratwizard and seuratv3wizard
RUN apt-get update && apt-get install -y libhdf5-dev
RUN R -e "devtools::install_github('nasqar/SeuratWizard', upgrade_dependencies = FALSE)"
RUN R -e "devtools::install_version(package = 'Seurat', version = package_version('2.3.4'),upgrade_dependencies = F)"
RUN apt-get update && apt-get install -y libpython-dev python-pip
RUN R -e "devtools::install_github('nasqar/seuratv3wizard', upgrade_dependencies = FALSE,ref = 'nasqarfix')"
RUN R -e "devtools::install_github(lib='/usr/local/lib/R/site-library/SeuratV3Wizard/shiny/SeuratLib',repo = 'satijalab/seurat', force=T)"
RUN R -e "devtools::install_github(repo = 'ChristophH/sctransform')"
RUN pip install cellbrowser
RUN pip install umap-learn

# download apps
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/yan-cri/DEApp/archive/master.zip', destfile = 'deapp.zip'); unzip(zipfile = 'deapp.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/GeneCountMerger/archive/master.zip', destfile = 'genecountmerger.zip'); unzip(zipfile = 'genecountmerger.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/nasqar/deseq2shiny/archive/master.zip', destfile = 'deseq2shiny.zip'); unzip(zipfile = 'deseq2shiny.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/aghozlane/shaman/archive/master.zip', destfile = 'shaman.zip'); unzip(zipfile = 'shaman.zip')"
RUN R -e "setwd(dir = '/tmp/'); download.file(url = 'https://github.com/jminnier/STARTapp/archive/master.zip', destfile = 'startapp.zip'); unzip(zipfile = 'startapp.zip')"

# clusterprofiler apps


# Copy configuration files into the Docker image
COPY docker_files/shiny-server.conf  /etc/shiny-server/shiny-server.conf
COPY . /srv/shiny-server
# Copy further configuration files into the Docker image
COPY docker_files/shiny-server.sh /usr/bin/shiny-server.sh
COPY docker_files/sitemap.xml /srv/shiny-server/

RUN mv /tmp/DEApp-master /srv/shiny-server/DEApp
RUN mv /tmp/GeneCountMerger-master /srv/shiny-server/GeneCountMerger
RUN mv /tmp/deseq2shiny-master /srv/shiny-server/deseq2shiny
RUN mv /tmp/shaman-master /srv/shiny-server/shaman
RUN mv /tmp/STARTapp-master /srv/shiny-server/STARTapp

RUN chown -R shiny:shiny /srv/shiny-server
RUN chmod -R 777 /usr/local/lib/R/*/SeuratV3Wizard/shiny/www
RUN chmod -R 777 /srv/shiny-server/tsar_nasqar

#RUN usermod -aG sudo shiny

# Make the ShinyApp available at port 80
EXPOSE 80

CMD ["/usr/bin/shiny-server.sh"]

![alt text](nasqar_bar.png "NASQAR")

## NASQAR (Nucleic Acid SeQuence Analysis Resource): 
### A web-based platform for High-throughput sequencing data analysis and visualization
- This repo contains the source code for the NASQAR homepage (http://nasqar.abudhabi.nyu.edu/)
- Below are links to github repos for the apps contained in NASQAR
- The Dockerfile can be used to build the latest image of NASQAR
- The latest Docker image for nasqar is available via DockerHub aymanm/nasqarall:nasqar

### Run using docker (Recommended):
Make sure Docker (version >= 17.03.0-ce) is installed.
```
docker run -p 80:80 aymanm/nasqarall:nasqar
```
This will run on port 80

To run on a different port:
```
docker run -p 8083:80 aymanm/nasqarall:nasqar
```
This will run on port 8083

---
NASQAR Custom apps:
- [SeuratV3Wizard (scRNA)](https://github.com/nasqar/seuratv3wizard)
- [SeuratWizard (scRNA)](https://github.com/nasqar/SeuratWizard)
- [deseq2shiny (Bulk RNA)](https://github.com/nasqar/deseq2shiny)
- [GeneCountMerger (Pre-processing)](https://github.com/nasqar/GeneCountMerger)
- [ClusterProfShinyGSEA](https://github.com/nasqar/ClusterProfShinyGSEA)
- [ClusterProfShinyORA](https://github.com/nasqar/ClusterProfShinyORA)

Other open-source apps:
- [STARTapp](https://github.com/jminnier/STARTapp)
- [DEApp](https://github.com/yan-cri/DEApp)
- [Shaman](https://github.com/aghozlane/shaman)

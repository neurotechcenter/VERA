# VERA [![DOI](https://zenodo.org/badge/265023008.svg)](https://zenodo.org/badge/latestdoi/265023008)
***V***ersatile ***E***lectrode Localization F***ra***mework was built to simplify electrode localization in ECoG and sEEG. As more and more invasive electrophysiological techniques become available, so do algorithms to make localization as accurate and seamless as possible. Unfortunately, a lot of these methods come with their own tool, making it difficult to compare approaches or unify data structures.

VERA was specifically built to solve this problem. The framework allows other tools to be integrated into existing pipelines without changing the localization pipeline.

# Prerequisites
- **MATLAB** (2018b or later)
  - [Computer Vision Toolbox](https://www.mathworks.com/products/computer-vision.html)
  - [Image Processing Toolbox](https://www.mathworks.com/products/image.html)
  - [MATLAB Report Generator](https://www.mathworks.com/products/report-generator.html)
  - [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)

For many of the common pipelines, you will also need:
  - [Freesurfer](https://surfer.nmr.mgh.harvard.edu/) (For Windows, use our [Freesurfer4Windows](https://github.com/neurotechcenter/Freesurfer4Windows) installer tool)
  - [SPM12](https://github.com/spm/spm)
  - [Neurotechnologies Center Report Generator](https://github.com/neurotechcenter/ReportGenerator/)

# Quick Guide
## Installation & Startup
VERA can be used by any MATLAB distribution later than MATLAB 2018b. Download the repository into an empty directory and run *startup_VERA.m*

## Common Issues
- In newer versions of MATLAB, Java-based GUI rendering has changed. 
- If you encounter a JAVA error such as:
        "Error using javaObjectEDT No class com.mathworks.consulting.widgets.tree.TreeNode can be located on the Java class path"
- install the [Widgets Toolbox - Compatibility Support](https://www.mathworks.com/matlabcentral/fileexchange/66235-widgets-toolbox-compatibility-support) from MATLAB add-ons. 

# WIKI

For more information check out [the Wiki](https://github.com/neurotechcenter/VERA/wiki)

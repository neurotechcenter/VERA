# VERA
***V***ersatile ***E***lectrode Localization F***ra***mework was built to simplify electrode localization in ECoG and sEEG. As more and more invasive electrophysiological techniques become available, so do algorithms to make localization as accurate and seamless as possible. Unfortunately, a lot of these methods come with their own tool, making it difficult to compare approaches or unify data structures.

VERA was specifically built to solve this problem. The framework allows other tools to be integrated into existing pipelines without changing the localization pipeline.

VERA was specifically built to solve this problem. The framework allows other tools to be integrated into existing pipelines without changing the localization pipeline.

# Quick Guide
## Installation & Startup
VERA can be used by any MatLab distribution later than Matlab 2016b. Download the repository into an empty directory and run *startup_off.m*

## GUI Overview

1. Menu
    * Loading and saving Projects
    * Closing Projects
1. 3D Menu
    * This menu is specifically to interact with 3D Content like Brain Surfaces
1. Pipeline Overview  
The Pipeline overview shows all steps of the current project. They will be shown in 3 different rubriks.
    * Inputs
Input Components are defined as Components that do not have any Inputs themselves, but produce Outputs
    * Processing
Processing Components require Inputs and either produce new Ouputs or alter existing ones
    * Outputs
Output Components require Input Components but do not produce Outputs themselves. These are typically used to create exporting formats.
1. Views  
This area is reserved for several different ways to visualize the data. This includes x,y,z views of MRIs and CTs or 3-dimensional Views of generated surfaces.

![VERA Startup](/images/VERA_empty.png)



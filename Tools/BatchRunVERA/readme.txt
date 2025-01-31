BatchRunVERA: Automated Multi-Project Execution Script
------------------------------------------------------

The BatchRunVERA script (found in VERA/Tools/BatchRunVERA) is designed to automate the execution of multiple VERA (Versatile Electrode localization fRAmework) projects in sequence without requiring user input during the process. This allows for efficient processing of multiple subjects in a single run.

Requirements
------------

1. Create VERA Project Folders
   Create individual VERA project folders for each subject you wish to run.

2. Copy the Pipeline to Each Project Folder
   Copy the pipeline you want to execute into each project folder. Make sure to specify the correct paths to the required input files for the relevant components in these pipeline copies. Note that this file must be named 'pipeline.pwf' for each folder.

3. Modify BatchRunVERA.m
   Edit the BatchRunVERA.m script to correctly reference the project folder names for each subject. This step ensures the script will target the correct folders during execution.

4. Run BatchRunVERA.m
   Execute the script from the VERA/Tools/BatchRunVERA directory to start processing the projects.

Tips for Setting Up Your Pipeline
----------------------------------

1. Load the Pipeline into the Pipeline Designer Tool
   Open the pipeline you want to use in the PipelineDesigner tool. Review and modify the pipeline components to ensure all required components are correctly specified.

2. Modify Component Inputs
   Each pipeline component may have specific input requirements. For each component, ensure you provide the correct path to the necessary files. Inputs can be specified as absolute paths or relative paths, where relative paths are relative to the current project folder.

3. Sample Pipeline with Inputs
   A sample pipeline with pre-configured inputs is included in this folder. Below are specific instructions for setting up commonly used components:

   - FileLoader:
     Specify the path to a DICOM or NIfTI file that contains the data to load. If loading dicom files, choose the path to any one .dcm file.

   - ElectrodeDefinitionConfiguration:
     Provide the path to an Excel file that defines the electrode configuration. An example file is available in VERA/Components/ElectrodeDefinition.

   - ImportROSFile:
     Provide the path to a folder containing the ROSA executed plan. This plan should have been generated previously during the setup phase.

   - LoadFreeviewPointFile:
     Specify the path to a folder containing .dat files with electrode coordinates. Ensure that the filenames match those specified in the ElectrodeDefinition configuration.

   - EEGElectrodeNames:
     Provide the path to a file (either BCI2000 data file or Excel file) containing the mapping between implanted electrode names and recorded electrode names. A template excel file can be found in VERA/Tools/ElectrodeNamesKey.

4. Default Data Output Location
   By default, the processed data will be saved in the DataOutput folder within each subject's VERA project folder.

Example Directory Structure
---------------------------

To help visualize the organization of your project folders, here’s a typical structure:

/Subject_Imaging
    /Subject1
        /data
            BCI2000File.dat
        /imaging
            /dicom
            /ct
            /mri
        /electrodes
            .dat files
        /notes
            ElectrodeDefinition.xlsx
            ElectrodeNamesKey.xlsx
            /ROSA_executed
                .ros file
                /dicom
                /RAS_data

/VERA_Projects
    /VERA_Subject1
        pipeline.pwf
    /VERA_Subject2
        pipeline.pwf

- Each Subject folder contains a pipeline configuration file (pipeline.pwf) that points to the relevant imaging data paths for that subject.

Troubleshooting
---------------

- Missing Files: Double-check that all required files (e.g., electrode definitions, DICOM/NIfTI files) are correctly placed in the respective project folders.
- Incorrect Paths: If the paths are not correct, VERA will present a file load dialog.

By following these instructions, you’ll be able to efficiently run multiple VERA projects in sequence, minimizing manual input and streamlining the analysis process.

%% Documentation   
% Example script to create a Campbell diagram with OpenFAST
%
% NOTE: this script is only an example.
% Adapt this scripts to your need, by calling the different subfunctions presented.
%
%% Initialization
clear all; close all; clc; 
restoredefaultpath;
addpath(genpath('C:/Work/FAST/matlab-toolbox'));

%% Parameters

% Main Flags
writeFSTfiles = true;      % write FAST input files for linearization
runFST        = true;      % run FAST simulations
postproLin    = true;      % Postprocess .lin files, perform MBC, and write XLS or CSV files
outputFormat  ='XLS';      % Output format XLS, or CSV

% Main Inputs
FASTexe = '..\..\_ExampleData\openfast2.3_x64s.exe'; % path to an openfast executable
templateFstFile     = '../../_ExampleData/5MW_Land_Lin_Templates/Main_5MW_Land_Lin.fst'; 
%      Template file used to create linearization files. 
%      This template file should point to a valid ElastoDyn file, and,
%      depending on the linearization type, valid AeroDyn, InflowWind and Servodyn files.
%      The template files can be in the `simulationFolder` or a separate folder.

simulationFolder    = '../../_ExampleData/5MW_Land_Lin/';
%      Folder where OpenFAST simulations will be run for the linearization.
%      OpenFAST input files for each operating point will be created there.
%      Should contain all the necessary files for a OpenFAST simulation.
%      Will be created if does not exists.

operatingPointsFile = 'LinearizationPoints_NoServo.csv'; 
%      File defining the operating conditions for linearization (e.g. RotorSpeeed, WindSpeed).
%      See function `readOperatingPoints` for more info.
%      You can define this data using a matlab structure, but an input file is recommended.

%% --- Step 1: Write OpenFAST inputs files for each operating points 
% NOTE: 
%      The function can take an operatingPointsFile or the structure OP 
%      Comment this section if the inputs files were already generated
%      See function writeLinearizationFiles for key/value arguments available: 
%      The key/values are used to:
%        - override options of the main fst file (e.g. CompServo, CompAero) 
%        - set some linearization options (e.g. simTime, NLinTimes)
%      `simTime` needs to be large enough for a periodic equilibrium to be reached
%      (trim option will be available in a next release of OpenFAST)
if writeFSTfiles
    FSTfilenames = writeLinearizationFiles(templateFstFile, simulationFolder, operatingPointsFile, 'simTime',300,'NLinTimes',12); % NOTE: simTime and NLinTimes given as examples
end
%% --- Step 2: run OpenFAST 
% NOTE: 
%      Comment this section if the simulations were already run
%      Potentially write a batch file for external run (can be more conveninet for many simulations).
%      Batch and commands are relative to the parent directory of the batch file.
if runFST
    [FASTfilenames] = getFullFilenamesOP(simulationFolder, operatingPointsFile);
    % --- Option 1: Batch
    [FASTcommands, batchFilename, runFolder] = writeBatch([simulationFolder '/_RunFAST.bat'], FSTfilenames, FASTexe);
    %runBatch(batchFilename, runFolder); 
    % --- Option 2: direct calls
    runFAST(FSTfilenames, FASTexe); 
end

%% --- Step 3: Run MBC, identify modes and generate XLS or CSV file
% NOTE:  
%      Select CSV output format if XLS is not available
%        - XLS: one output file is generated (existing sheets will be overriden, not new sheets)
%        - CSV: several output files are generated
%      The mode identification currently needs manual tuning (modes might be swapped): 
%        - XLS: modify the `ModesID` sheet of the Excel file generated to do this tuning
%        - CSV: modify the csv file `*_ModesID.csv` if you chose CSV output.
%      To avoid the manual identification to be overriden, you can: 
%        - XLS: use a new sheet , e.g. 'ModesID_Sorted` and use this in Step 4
%        - CSV: create a new file, e.g. 'Campbell_ModesID_Sorted.csv` and this for step 4
if postproLin
    [ModesData, outputFiles] = postproLinearization(simulationFolder, operatingPointsFile, outputFormat);
end


%% --- Step 4: Campbell diagram plot
if isequal(lower(outputFormat),'xls')

    %  NOTE: more work is currently needed for the function below
    plotCampbellData([simulationFolder '/Campbell_DataSummary.xlsx'], 'WS_ModesID');

elseif isequal(lower(outputFormat),'csv')

    % python script is used for CSV (or XLS)
    fprintf('\nUse python script to visualize CSV data: \n\n')
    fprintf('usage:  \n')
    fprintf('python plotCampbellData.py XLS_OR_CSV_File [WS_OR_RPM] [sheetname]\n\n')

end

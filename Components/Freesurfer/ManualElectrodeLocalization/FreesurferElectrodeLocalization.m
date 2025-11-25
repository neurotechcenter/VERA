classdef FreesurferElectrodeLocalization < AComponent
    %FreesurferElectrodeLocalization - Manual Electrode Localization
    %through Freesurfer 
    %Component will open Freeview to fill in Point Sets 
    
    properties
        CTIdentifier %Identifier for CT Volume Data 
        ElectrodeDefinitionIdentifier %Identifier for ElectrodeDefinitions
        ElectrodeLocationIdentifier % Identifier for Output Electrode Locations
        TrajectoryIdentifier % Identifier for Output Electrode Locations
    end
    
    methods
        function obj = FreesurferElectrodeLocalization()
            obj.CTIdentifier='CT';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.TrajectoryIdentifier='Trajectory';
        end
        function Publish(obj)
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOptionalInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOptionalInput(obj.TrajectoryIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.RequestDependency('Freesurfer','folder');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end
        function Initialize(obj)
            path=obj.GetDependency('Freesurfer');
            addpath(fullfile(path,'matlab'));
            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE bash >nul 2>nul echo %ERRORLEVEL%') == 1)
                   error('If you want to use Freesurfer components on windows, the Windows 10 Ubuntu subsystem is required!');
               else
                   disp('Found ubuntu subsystem on Windows 10!');
                   disp('This Component requires GUI Access to freeview, make sure you can run freeview from the Linux subsystem (requires Xserver installed on windows)');
               end
            end
            
        end
        
        function [electrodes] = Process(obj,ct,elDef,varargin)
            %create a waypoint file for each definition
            acceptAll = false;
            override = true;
            wayptfileIds=cell(length(elDef.Definition),1);
            for i=1:length(varargin)
                if(strcmp(varargin{i},obj.ElectrodeLocationIdentifier))
                    eLocsIn=varargin{i+1};
                end
                if(strcmp(varargin{i},obj.TrajectoryIdentifier))
                    traj=varargin{i+1};
                end
            end
            freesurferPath=obj.GetDependency('Freesurfer');
            compPath=obj.ComponentPath;
            ctpath=GetFullPath(ct.Path);
            if(~ispc)
                shellcmd=['export FREESURFER_HOME=' freesurferPath  ' \n '...
                      'source $FREESURFER_HOME/SetUpFreeSurfer.sh \n ' ...
                      'export FS_LOAD_DWI=0 \n ' ...
                      'freeview -v "' ctpath '" '];
            else
                subsyspath=obj.GetDependency('UbuntuSubsystemPath');
                w_freesurferPath=convertToUbuntuSubsystemPath(freesurferPath,subsyspath);
                shellcmd=['export DISPLAY=:0 \n export FREESURFER_HOME=' w_freesurferPath  ' \n '...
                          'source $FREESURFER_HOME/SetUpFreeSurfer.sh \n ' ...
                          'export FS_LOAD_DWI=0 \n ' ...
                          'freeview -v "' convertToUbuntuSubsystemPath(ctpath,subsyspath) '" '];
            end
            traj_files={};
            for i=1:length(elDef.Definition)
                str='\n';
                if(exist('eLocsIn','var'))
                    currLocs=find(eLocsIn.DefinitionIdentifier == i);
                    for l=1:length(currLocs)
                        str=[str num2str(eLocsIn.Location(currLocs(l),:)) '\n'];
                    end
                    numeDefEls=length(currLocs);
                else
                    numeDefEls=0;
                end
                str=[str 'info \nnumpoints ' num2str(numeDefEls) '\nuseRealRAS 1'];
                
                wayptfileIds{i}=[compPath '/' regexprep(regexprep(elDef.Definition(i).Name,' +','_'),'[<>:"/\|?*]','_${num2str(cast($0,''uint8''))}') '.dat'];
                if(exist('traj','var'))
                str_traj='\n';
                currLocs=find(traj.DefinitionIdentifier == i);
                for l=1:length(currLocs)
                    str_traj=[str_traj num2str(traj.Location(currLocs(l),:)) '\n'];
                end
                numeDefEls_traj=length(currLocs);
                    
                str_traj=[str_traj 'info \nnumpoints ' num2str(numeDefEls_traj) '\nuseRealRAS 1'];   
                traj_files{i}=[compPath '/traj_' regexprep(regexprep(elDef.Definition(i).Name,' +','_'),'[<>:"/\|?*]','_${num2str(cast($0,''uint8''))}') '_' num2str(elDef.Definition(i).NElectrodes)  '.dat'];
                fileID = fopen(traj_files{i},'w');
                fprintf(fileID,str_traj);
                fclose(fileID);

                end
                    
                %wayptfileIds{i}=regexprep(wayptfileIds{i},'[<>:"/\|?*]','_${num2str(sscanf(''a'',''%x''))}');
                if(~acceptAll && exist(wayptfileIds{i},'file'))
                    answer=questdlg(['Existing Point file for ' elDef.Definition(i).Name ' found! ',...
                        '''Override all'' with results from the previous step? Or ''Keep all'' with results from the last run of Freesurfer Electrode Localization?'],'','Override all','Keep all','Keep all');
                    switch(answer)
                        case 'Override'
                            override = true;
                        case 'Override all'
                            acceptAll =true;
                            override = true;
                        case 'Keep'
                            override = false;
                        case 'Keep all'
                            acceptAll=true;
                            override = false;
                    end
                end
                if(override || ~exist(wayptfileIds{i},'file'))
                    fileID = fopen(wayptfileIds{i},'w');
                    fprintf(fileID,str);
                    fclose(fileID);
                end
                %else
                %    warning('Files already exist!, To empty files, please remove from directory');
                %end
                if(ispc)
                    shellcmd=[shellcmd '-c "' convertToUbuntuSubsystemPath(wayptfileIds{i},subsyspath) '" '];
                else
                    shellcmd=[shellcmd '-c "' wayptfileIds{i} '" '];
                end
            end
            for i=1:length(traj_files)
                if(ispc)
                    shellcmd=[shellcmd '-c "' convertToUbuntuSubsystemPath(traj_files{i},subsyspath) '" '];
                else
                    shellcmd=[shellcmd '-c "' traj_files{i} '" '];
                end
            end
            %open freesurfer with CT and waypoint files
            fileID = fopen(fullfile(compPath,'runFreeview.sh'),'w');
          %  obj.Log(['Opening Freeview for Electrode localization: ' shellcmd]);
            fprintf(fileID,shellcmd);
            fclose(fileID);
            if(ispc)
                [status,cmdout] = systemWSL(['chmod +x ''' convertToUbuntuSubsystemPath(fullfile(compPath,'runFreeview.sh'),subsyspath) ''''],'-echo');
                % [status,cmdout] = system(['chmod -R +x ' freesurferPath],'-echo');
                if status ~= 0
                    error(['Error Running Freeview: ',cmdout]);
                end

                [status,cmdout] = systemWSL(['''' convertToUbuntuSubsystemPath(fullfile(compPath,'runFreeview.sh'),subsyspath) ''''],'-echo');
                if status ~= 0
                    error(['Error Running Freeview: ',cmdout]);
                end

            else
                [status,cmdout] = system(['chmod +x ''' fullfile(compPath,'runFreeview.sh') ''''],'-echo');
                % [status,cmdout] = system(['chmod -R +x ' freesurferPath],'-echo');
                if status ~= 0
                    error(['Error Running Freeview: ',cmdout]);
                end
                [status,cmdout] = system(['''' fullfile(compPath,'runFreeview.sh') ''''],'-echo');
                if status ~= 0
                    error(['Error Running Freeview: ',cmdout]);
                end
            end
            %read waypoint files 
            electrodes=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            for i=1:length(wayptfileIds)
                el=importelectrodes(wayptfileIds{i});
                if(size(el,1) ~= elDef.Definition(i).NElectrodes)
                    error(['Expected ' num2str(elDef.Definition(i).NElectrodes) ' for ' elDef.Definition(i).Type ' ' elDef.Definition(i).Name ' but total count was ' num2str(length(el))])
                end
                electrodes.Location=[electrodes.Location ;el];
                electrodes.DefinitionIdentifier=[electrodes.DefinitionIdentifier; i*ones(size(el,1),1)];
                
            end
            
            
        end
    end
end


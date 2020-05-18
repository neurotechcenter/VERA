classdef FreesurferElectrodeLocalization < AComponent
    %INPUTCOMPONENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CTIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = FreesurferElectrodeLocalization()
            obj.CTIdentifier='CT';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
        end
        function Publish(obj)
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOptionalInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            obj.RequestDependency('Freesurfer','folder');
            if(ispc)
                obj.RequestDependency('UbuntuSubsystemPath','folder');
            end
        end
        function Initialize(obj)
            path=obj.GetDependency('Freesurfer');
            addpath(genpath(path));
            if(ispc)
                obj.GetDependency('UbuntuSubsystemPath');
               if(system('WHERE ubuntu >nul 2>nul echo %ERRORLEVEL%') == 1)
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
            if((length(varargin) > 0) && strcmp(varargin{1},obj.ElectrodeLocationIdentifier)) %electoodes exist
                eLocsIn=varargin{2};
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
                
                wayptfileIds{i}=[compPath '/' regexprep(elDef.Definition(i).Name,' +','_') '.dat'];
                if(~acceptAll && exist(wayptfileIds{i},'file'))
                    answer=questdlg(['Existing Point file for ' elDef.Definition(i).Name ' found!'],'Override','Override', 'Override all','Keep' ,'Keep All');
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
            %open freesurfer with CT and waypoint files
            fileID = fopen(fullfile(compPath,'runFreeview.sh'),'w');
          %  obj.Log(['Opening Freeview for Electrode localization: ' shellcmd]);
            fprintf(fileID,shellcmd);
            fclose(fileID);
            if(ispc)
                system(['ubuntu run chmod +x ''' convertToUbuntuSubsystemPath(fullfile(compPath,'runFreeview.sh'),subsyspath) ''''],'-echo');
                %system(['chmod -R +x ' freesurferPath],'-echo');
                system(['ubuntu run ''' convertToUbuntuSubsystemPath(fullfile(compPath,'runFreeview.sh'),subsyspath) ''''],'-echo');
            else
                system(['chmod +x ''' fullfile(compPath,'runFreeview.sh') ''''],'-echo');
                %system(['chmod -R +x ' freesurferPath],'-echo');
                system(['''' fullfile(compPath,'runFreeview.sh') ''''],'-echo');
            end
            %read waypoint files 
            electrodes=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            for i=1:length(wayptfileIds)
                el=importelectrodes(wayptfileIds{i});
                if(length(el) ~= elDef.Definition(i).NElectrodes)
                    error(['Expected ' num2str(elDef.Definition(i).NElectrodes) ' for ' elDef.Definition(i).Type ' ' elDef.Definition(i).Name ' but total count was ' num2str(length(el))])
                end
                electrodes.Location=[electrodes.Location ;el];
                electrodes.DefinitionIdentifier=[electrodes.DefinitionIdentifier; i*ones(length(el),1)];
                
            end
            
            
        end
    end
end


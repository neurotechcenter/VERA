classdef ANTCoregistration < AComponent
    %ANTCoregistration This component uses ANTs (https://github.com/ANTsX/ANTs)
    %to perform rigid, Affine, or nonlinear coregistration
    %Type specified which coregistration will be perfomed:
    %acceptable values are Rigid, Affine, Syn
    
    properties
        ReferenceIdentifier
        CoregistrationIdentifier
        SurfaceIdentifier
        Type
        ElectrodeLocationIdentifier
    end
    properties (Constant, Access = private)
        RegistrationAlgorithms = {'Rigid','Affine','SyN'}
    end
    
    methods
        function obj = ANTCoregistration()
            obj.ReferenceIdentifier='MNI';
            obj.CoregistrationIdentifier='MRI';
            obj.Type='SyN';
            obj.ElectrodeLocationIdentifier='';
            obj.SurfaceIdentifier='';
        end
        
        function Publish(obj)
            obj.AddInput(obj.ReferenceIdentifier,'Volume');
            obj.AddInput(obj.CoregistrationIdentifier,'Volume');
            
            obj.AddOutput(obj.CoregistrationIdentifier,'Volume');
            if(~isempty(obj.SurfaceIdentifier))
                obj.AddInput(obj.SurfaceIdentifier,'Surface');
                obj.AddOutput(obj.SurfaceIdentifier,'Surface');
            end
            if(~isempty(obj.ElectrodeLocationIdentifier))
                obj.AddInput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
                obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
            end
            obj.RequestDependency('ANT','folder');
        end

        function Initialize(obj)
            ant_dep=obj.GetDependency('ANT');
            if(~exist(fullfile(ant_dep,'antsRegistration'),'file'))
                error('Could not file the correct ANT executables within the specified ANT folder, please make sure you select the bin folder containing antsRegistration!')
            end
            if(~any(strcmp(obj.Type,obj.RegistrationAlgorithms)))
                error('Invalid Registration algorithm selected; Choose from: Rigid, Affine or SyN');
            end

        end

        function varargout=Process(obj,refVol,coregVol,addin1,addin2)
            csvM=[];
            hasSurf=~isempty(obj.SurfaceIdentifier);
            hasElLocs=~isempty(obj.ElectrodeLocationIdentifier);
            if(hasSurf)
                surf=addin1;
                csvM=surf.Model.vert;
                if hasElLocs
                    elLocs=addin2;
                    csvM=[csvM; elLocs.Location];
                end
            elseif hasElLocs
                elLocs=addin1;
                csvM=elLocs.Location;
            end
            
            %add T and comment to match csv specs
            csvM=[csvM zeros(size(csvM,1),1)];

            ant_path=obj.GetDependency('ANT');
            tmpPath=obj.GetTempPath();
            tmpPathcsv=fullfile(tmpPath,'pointset.csv');
            if(~isempty(csvM))
                T = array2table(csvM);
                T.Properties.VariableNames = {'x','y','z','t'};
                T.x=-T.x;
                T.y=-T.y;
                
            else
                T=table(1, 1, 1, 1,'VariableNames',{'x','y','z','t'});
            end
            writetable(T,tmpPathcsv);
            
            ref_path=GetFullPath(refVol.Path);
            coreg_path=GetFullPath(coregVol.Path);
            ant_script_image=fullfile(fileparts((mfilename('fullpath'))),'/scripts/ANTS_IMAGE.sh');
            ant_script_rigid=fullfile(fileparts((mfilename('fullpath'))),'/scripts/ANTS_PTS_RIGID.sh');
            ant_script_SyN=fullfile(fileparts((mfilename('fullpath'))),'/scripts/ANTS_PTS_SyN.sh');
            coregType=find(strcmp(obj.Type,obj.RegistrationAlgorithms));
            
            if(ispc)
                subsyspath=obj.GetDependency('UbuntuSubsystemPath');
                ant_script_image_wsl=convertToUbuntuSubsystemPath(ant_script_image,subsyspath);
                ant_script_rigid_wsl=convertToUbuntuSubsystemPath(ant_script_rigid,subsyspath);
                ant_script_SyN_wsl=convertToUbuntuSubsystemPath(ant_script_SyN,subsyspath);
                ant_path_wsl=convertToUbuntuSubsystemPath(ant_path,subsyspath);
                ref_path_wsl=convertToUbuntuSubsystemPath(ref_path,subsyspath);
                tmpPathcsv_wsl=convertToUbuntuSubsystemPath(tmpPathcsv,subsyspath);
                coreg_path_wsl=convertToUbuntuSubsystemPath(coreg_path,subsyspath);
                tmpPath_wsl=convertToUbuntuSubsystemPath(tmpPath,subsyspath);

                systemWSL(['chmod +x ''' ant_script_image_wsl ''''],'-echo');
                shellcmd=[ant_script_image_wsl ...
                ' ''' ant_path_wsl '''' ...
                ' ''' ref_path_wsl '''' ...
                ' ''' coreg_path_wsl '''' ...
                ' ''' tmpPath_wsl  '''' ...
                ' ''' num2str(coregType) ''''];
                systemWSL(shellcmd,'-echo');


                systemWSL(['chmod +x ''' ant_script_rigid_wsl ''''],'-echo');
                shellcmd=[ant_script_rigid_wsl ...
                ' ''' ant_path_wsl '''' ...
                ' ''' tmpPathcsv_wsl '''' ...
                ' ''' tmpPath_wsl  '''' ];
                systemWSL(shellcmd,'-echo');

                if(~exist(fullfile(tmpPath,'reg_out_rigid.csv'),'file'))
                    error('No Rigid/affine point transformation created!');
                end
                V=readtable(fullfile(tmpPath,'reg_out_rigid.csv'));
                
                if(coregType >2) %we first need to transform points into LPS and than back
                    writetable(V,tmpPathcsv);
                    systemWSL(['chmod +x ''' ant_script_SyN_wsl ''''],'-echo');
                    shellcmd=[ant_script_SyN_wsl ...
                    ' ''' ant_path_wsl '''' ...
                    ' ''' tmpPathcsv_wsl '''' ...
                    ' ''' tmpPath_wsl  '''' ];
                    systemWSL(shellcmd,'-echo');  
                    if(~exist(fullfile(tmpPath,'reg_out_syn.csv'),'file'))
                        error('No syn point transformation created!');
                    end
                    V=readtable(fullfile(tmpPath,'reg_out_syn.csv'));
                end
                V.x=-V.x;
                V.y=-V.y;
            else
                system(['chmod +x ''' ant_script_image ''''],'-echo');
                shellcmd=[ant_script_image ...
                ' ''' ant_path '''' ...
                ' ''' ref_path '''' ...
                ' ''' coreg_path '''' ...
                ' ''' tmpPath  '''' ...
                ' ''' num2str(coregType) ''''];
                system(shellcmd,'-echo');


                system(['chmod +x ''' ant_script_rigid ''''],'-echo');
                shellcmd=[ant_script_rigid ...
                ' ''' ant_path '''' ...
                ' ''' tmpPathcsv '''' ...
                ' ''' tmpPath  '''' ];
                system(shellcmd,'-echo');

                if(~exist(fullfile(tmpPath,'reg_out_rigid.csv'),'file'))
                    error('No Rigid/affine point transformation created!');
                end
                V=readtable(fullfile(tmpPath,'reg_out_rigid.csv'));
                
                if(coregType >2) %we first need to transform points into LPS and than back
                    writetable(V,tmpPathcsv);
                    system(['chmod +x ''' ant_script_SyN ''''],'-echo');
                    shellcmd=[ant_script_SyN ...
                    ' ''' ant_path '''' ...
                    ' ''' tmpPathcsv '''' ...
                    ' ''' tmpPath  '''' ];
                    system(shellcmd,'-echo');  
                    if(~exist(fullfile(tmpPath,'reg_out_syn.csv'),'file'))
                        error('No syn point transformation created!');
                    end
                    V=readtable(fullfile(tmpPath,'reg_out_syn.csv'));
                end
                V.x=-V.x;
                V.y=-V.y;
            end
            if(~exist(fullfile(tmpPath,'reg_out_111_ants.nii'),'file'))
                error('ANT script failed to produce all outputs!');
            end
            V=table2array(V);
            coregVol=obj.CreateOutput(obj.CoregistrationIdentifier);
            coregVol.LoadFromFile(fullfile(tmpPath,'reg_out_111_ants.nii'));

            varargout{1}=coregVol;

            if(hasSurf)
                surfOut=obj.CreateOutput(obj.SurfaceIdentifier,surf);
                surfOut.Model.vert=V(1:size(surfOut.Model.vert,1),1:3);
                varargout{2}=surfOut;
            end
            
            
            

            if(hasElLocs)
                elOut=obj.CreateOutput(obj.ElectrodeLocationIdentifier,elLocs);
                if(hasSurf)
                    elOut.Location=V(size(surfOut.Model.vert,1)+1:end,1:3);
                    varargout{3}=elOut;
                else
                    elOut.Location=V(1:end,1:3);
                    varargout{2}=elOut;
                end
                
                 %surfOut=obj.CreateOutput(obj.SurfaceIdentifier);
            end
            

        end
    end
end


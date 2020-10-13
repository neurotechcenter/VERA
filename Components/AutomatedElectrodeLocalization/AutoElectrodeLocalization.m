classdef AutoElectrodeLocalization < AComponent
    %AutoElectrodeLocalization - Automated Electrode Localization
    %Automatically determines electrode locations for Strips and Grids
    
    properties
        CTIdentifier
        ElectrodeDefinitionIdentifier
        ElectrodeLocationIdentifier
    end
    
    methods
        function obj = AutoElectrodeLocalization()
            %AUTOELECTRODELOCALIZATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.CTIdentifier='CT';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
        end
        
function Publish(obj)
            obj.AddInput(obj.CTIdentifier,'Volume');
            obj.AddInput(obj.ElectrodeDefinitionIdentifier,'ElectrodeDefinition');
            obj.AddOutput(obj.ElectrodeLocationIdentifier,'ElectrodeLocation');
        end
        
        function Initialize(obj)
            
        end
        
        function [elLocation] = Process(obj,ct,elDefinition)
            tic
            f=[];
            o.PlotFcns=[];
            o.OutputFcn=[];
            o.TolX=1;
          %  o = optimoptions('fmincon','UseParallel',true);
            elLocation=obj.CreateOutput(obj.ElectrodeLocationIdentifier);
            x0=double(max(max(max(ct.Image.img)))*0.8);
            lb=[double(min(min(min(ct.Image.img)))) 5 0 0.05];
            ub=[double(max(max(max(ct.Image.img)))) inf inf 0.3];
            Striplocs={};
            GridLocs={};
            id=find(strcmp('Strip',{elDefinition.Definition.Type}));
            strips=elDefinition.Definition(id);
          
            n_str=1;
            search_strips=[];
            while(~isempty(strips))
                del_list=[];
                search_strips(n_str).Type=strips(1).Type;
                search_strips(n_str).NElectrodes=strips(1).NElectrodes;
                search_strips(n_str).Spacing=strips(1).Spacing;
                search_strips(n_str).Volume=strips(1).Volume;
                search_strips(n_str).NType=1;
                search_strips(n_str).Id=id(1);
                strips(1)=[];
                id(1)=[];
                for i=1:length(strips)
                    if(strips(i).NElectrodes == search_strips(n_str).NElectrodes && ...
                            strips(i).Volume == search_strips(n_str).Volume && ...
                            strips(i).Spacing == search_strips(n_str).Spacing)
                        search_strips(n_str).NType=search_strips(n_str).NType+1;
                        search_strips(n_str).Id=[search_strips(n_str).Id id(i)];
                        del_list=[del_list i];
                    end
                end
                strips(del_list)=[];
                id(del_list)=[];
                n_str=n_str+1;
            end
            n_str=1;
            if(~isempty(search_strips))
                [~,sorting]=sort([search_strips.NElectrodes],'descend');
                strips=search_strips(sorting);
            end
            id=find(strcmp('Grid',{elDefinition.Definition.Type}));
            grids=elDefinition.Definition(id);
            search_grids=[];
            while(~isempty(grids))
                del_list=[];
                search_grids(n_str).Type=grids(1).Type;
                search_grids(n_str).NElectrodes=grids(1).NElectrodes;
                search_grids(n_str).Spacing=grids(1).Spacing;
                search_grids(n_str).Volume=grids(1).Volume;
                search_grids(n_str).NType=1;
                search_grids(n_str).Id=id(1);
                grids(1)=[];
                id(1)=[];
                for i=1:length(grids)
                    if(grids(i).NElectrodes == search_grids(n_str).NElectrodes && ...
                            grids(i).Volume == search_grids(n_str).Volume && ...
                            grids(i).Spacing == search_grids(n_str).Spacing)
                        search_grids(n_str).NType=search_grids(n_str).NType+1;
                        search_grids(n_str).Id=[search_grids(n_str).Id id(i)];
                         del_list=[del_list i];
                    end
                end
                grids(del_list)=[];
                id(del_list)=[];
                n_str=n_str+1;
            end
            grids=search_grids;
             mod_vol=1/(ct.Image.hdr.dime.pixdim(2)*ct.Image.hdr.dime.pixdim(3)*ct.Image.hdr.dime.pixdim(4));
             dist_mod=1/mean(ct.Image.hdr.dime.pixdim(2:4));
            for i=1:length(strips)
                strips(i).Spacing=strips(i).Spacing*dist_mod;
                strips(i).Volume=strips(i).Volume*mod_vol;
            end
            for i=1:length(grids)
                grids(i).Spacing=grids(i).Spacing*dist_mod;
                grids(i).Volume=grids(i).Volume*mod_vol;
            end
            
            
            disp('Searching for Strips....');
            ct_fmin=(ct.Image.img);
            fullmask=ones(size(ct_fmin));
            strps_found=0;
            %f=figure;
            for i=1:length(strips)
                costfun=@(x) (findElectrodes(ct_fmin,x(1),x(2),x(3),x(4),strips(i),f));
                [res_opt, fval]=fminsearchbnd(costfun,[x0 1 1 0.1],lb,ub,o);
                [~,Striplocs{i}]=findElectrodes(ct_fmin,res_opt(1),res_opt(2),res_opt(3),res_opt(4),strips(i),f);
                disp(['Found ' num2str(size(Striplocs{i}.Locations,1)) ' Strips!']);
                smask=createElectrodeMask(size(ct_fmin),Striplocs{i});
                fullmask=fullmask.*double(smask);
                ct_fmin=ct_fmin.*cast(smask,'like',ct_fmin);
                strps_found=strps_found+size(Striplocs{i}.Locations,1);
            end
            disp(['Total Found ' num2str(strps_found) ' Strips!']);
            if(strps_found ~= 0)
                del_list=[];
                for iGr=1:length(Striplocs)
                    grid=Striplocs{iGr};
                    for ig=1:size(grid.Locations,1)
                        strips(iGr).NType=strips(iGr).NType-1;
                        elLocation.Location=[elLocation.Location; squeeze(grid.Locations(ig,:,:))];
                        elLocation.DefinitionIdentifier=[elLocation.DefinitionIdentifier; grid.Information.Id(ig)*ones(size(grid.Locations,2),1)];
                    end
                    strips(iGr).Id(1:size(grid.Locations,1))=[];
                    if(strips(iGr).NType <= 0)
                        del_list(end+1)=iGr;
                    end
                end
                                    
                 strips(del_list)=[];
                   
            end
            
            disp('Searching for Grids....');
            grds_found=0;
          %  f=figure;
            for i=1:length(grids)
                costfun=@(x) (findElectrodes(ct_fmin,x(1),x(2),x(3),x(4),grids(i),f));
                [res_opt, fval]=fminsearchbnd(costfun,[x0 1 1 0.1],lb,ub,o);
                [~,Gridlocs{i},part_matches{i}]=findElectrodes(ct_fmin,res_opt(1),res_opt(2),res_opt(3),res_opt(4),grids(i),f);
                grds_found=grds_found+size(Gridlocs{i}.Locations,1);
                disp(['Found ' num2str(size(Gridlocs{i}.Locations,1)) ' Grids!']);
                smask=createElectrodeMask(size(ct_fmin),Gridlocs{i});
                ct_fmin=ct_fmin.*cast(smask,'like',ct_fmin);
                for iGr=1:length(grids(i).Id)
                    grid=Gridlocs{i};
                    if(size(grid.Locations,1) >= iGr)
                       elLocation.Location=[elLocation.Location; squeeze(grid.Locations(iGr,:,:))];
                       elLocation.DefinitionIdentifier=[elLocation.DefinitionIdentifier; grid.Information.Id(iGr)*ones(size(grid.Locations,2),1)];
                    else
                        grid=Gridlocs{i};
                        [~,I] = max(cellfun(@(x)size(x,1),part_matches{i}));
                        if(~isempty(I))
                             elLocation.Location=[elLocation.Location; part_matches{i}{I}];
                             elLocation.DefinitionIdentifier=[elLocation.DefinitionIdentifier; grid.Information.Id(iGr)*ones(size(part_matches{i}{I},1),1)];
                             part_matches{i}{I}=[];
                        end
                    end
                end
    
            end
            disp(['Total Found: ' num2str(grds_found) ' Grids!']);
%             if(grds_found ~= 0)
%                 for iGr=1;length(Gridlocs)
%                     grid=Gridlocs{iGr};
%                     for ig=1:size(grid.Locations,1)
%                         elLocation.Location=[elLocation.Location; squeeze(grid.Locations(ig,:,:))];
%                         elLocation.DefinitionIdentifier=[elLocation.DefinitionIdentifier; grid.Information.Id(ig)*ones(size(grid.Locations,2),1)];
%                     end
%                     grid.Information.Id(1:size(grid.Locations,1))=[];
%                 end
%                 
%             else
%                 for iGr=1;length(Gridlocs)
%                     grid=part_matches{iGr};
%                     [~,I] = max(cellfun(@(x)size(x,1),grid));
%                     if(~isempty(I))
%                         grid=grid{I};
%                         elLocation.Location=[elLocation.Location; grid];
%                         elLocation.DefinitionIdentifier=[elLocation.DefinitionIdentifier; grids(iGr).Id(iGr)*ones(size(grid,1),1)];
%                     end
%                  end
%             end
            
            if(strps_found < sum(strcmp('Strip',{elDefinition.Definition.Type})))
                disp('Trying to find remaining strips....');
                ub=[double(max(max(max(ct.Image.img)))) inf inf 0.30]; %increasing ub 
                fullmask=ones(size(ct_fmin));
                strps_found=0;
                Striplocs={};
                partial_matches={};
            %    f=figure;
                for i=1:length(strips)
                    costfun=@(x) (findElectrodes(ct_fmin,x(1),x(2),x(3),x(4),strips(i),f));
                    [res_opt, fval]=fminsearchbnd(costfun,[x0 1 1 0.1],lb,ub,o);
                    [~,Striplocs{i},partial_matches{i}]=findElectrodes(ct_fmin,res_opt(1),res_opt(2),res_opt(3),res_opt(4),strips(i),f);
                    disp(['Found ' num2str(size(Striplocs{i}.Locations,1)) ' Strips!']);
                    smask=createElectrodeMask(size(ct_fmin),Striplocs{i});
                    fullmask=fullmask.*double(smask);
                    ct_fmin=ct_fmin.*cast(smask,'like',ct_fmin);
                    strps_found=strps_found+size(Striplocs{i}.Locations,1);
                end
                disp(['Total Found ' num2str(strps_found) ' Strips!']);
                if(strps_found ~= 0)
                    for iGr=1;length(Striplocs)
                        grid=Striplocs{iGr};
                        for ig=1:size(grid.Locations,1)
                            elLocation.Location=[elLocation.Location; squeeze(grid.Locations(ig,:,:))];
                            elLocation.DefinitionIdentifier=[elLocation.DefinitionIdentifier; grid.Information.Id(ig)*ones(size(grid.Locations,2),1)];
                        end
                    end
                end
            end
            %transform the coordinates

            if(~isempty(elLocation.Location))
                elLocation.Location=(elLocation.Location(:,[2 1 3])-ct.Image.hdr.hist.originator([1 2 3])).*ct.Image.hdr.dime.pixdim([2 3 4]);
            end
            toc
        end
    end
end


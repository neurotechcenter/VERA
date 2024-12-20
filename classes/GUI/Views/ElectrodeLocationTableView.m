classdef ElectrodeLocationTableView < AView & uix.Grid
    %ElectrodeLocationTableView Table to show electrode locations including
    %names and labels
    % See also AView
    
    properties
        ElectrodeLocationIdentifier %Identifier for the Electrode Location to be shown
        ElectrodeDefinitionIdentifier
    end
    properties (Access = protected)
        gridDefinitionTable
    end
    
    methods
        function obj = ElectrodeLocationTableView(varargin)
            obj.ElectrodeLocationIdentifier='ElectrodeLocation';
            obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
            obj.gridDefinitionTable=uitable('Parent',obj,...
             'ColumnName',{'Channel','Channel Name','X','Y','Z','Label'},...
             'ColumnFormat',{'numeric','char','numeric','numeric','numeric','char'},'Enable','inactive');

             try
                uix.set( obj, varargin{:} )
             catch e
                delete( obj )
                e.throwAsCaller()
            end
        end

    end

   methods(Access = protected)
        function dataUpdate(obj)
           elLocs=[];
           eDef=[];
           obj.gridDefinitionTable.Data={};

           %check if ElectrodeLocation data exists
           if(isKey(obj.AvailableData,obj.ElectrodeLocationIdentifier))
                elLocs=obj.AvailableData(obj.ElectrodeLocationIdentifier);
                if(~isObjectTypeOf(elLocs,'ElectrodeLocation'))
                    return;
                end
           end
           
           %check if ElectrodeDefinition data exists
           if(isKey(obj.AvailableData,obj.ElectrodeDefinitionIdentifier))
                eDef=obj.AvailableData(obj.ElectrodeDefinitionIdentifier);
           end

            %create table for view
            tbl={};
            if(~isempty(elLocs))
               for i=1:size(elLocs.Location,1)
                   def_name=eDef.Definition(elLocs.DefinitionIdentifier(i)).Name;
                   chidx=find(find(elLocs.DefinitionIdentifier == elLocs.DefinitionIdentifier(i)) == i);
                   labels='';
                   try
                       for ii=1:length(elLocs.Label{i})
                           if(ii == 1)
                               labels=elLocs.Label{i}{ii};
                           else
                           labels=[labels ', ' elLocs.Label{i}{ii}];
                           end
                       end
                   catch
                   end
                   tbl(i,:)={i,[def_name num2str(chidx)],elLocs.Location(i,1),elLocs.Location(i,2),elLocs.Location(i,3),labels};

               end
            end
           obj.gridDefinitionTable.Data=tbl;
        end
   end
   
end


classdef ElectrodeDefinitionView < uix.Grid & AView & IComponentView
    %ElectrodeDefinitionView - View associated with the Electrode Definition
    % see also AView, IComponentView
    properties (Access = public)
        History % history of changes made in the view
        ElectrodeDefinitionIdentifier
    end
    properties (Access = protected)
        gridDefinitionTable
        buttonGrid
        deleteButton
        addButton
    end
    
    methods
        function obj = ElectrodeDefinitionView(varargin)

             obj.gridDefinitionTable=uitable('Parent',obj,...
                 'ColumnName',{'Select','Type','Name','# of electrodes','Spacing (mm)','Electrode Volume (mm3)'},...
                 'ColumnFormat',{'logical',ElectrodeDefinition.ElectrodeTypes,'char','numeric','numeric','numeric'},...
                 'ColumnEditable',[true,true,true,true,true,true],...
                 'CellEditCallback',@(~,~)obj.compUpdate());

             obj.buttonGrid=uix.Grid('Parent',obj);
             obj.deleteButton=uicontrol('Parent',obj.buttonGrid,'Style','pushbutton','String','Delete','Callback',@obj.deleteButtonPressed);
             obj.addButton=uicontrol('Parent',obj.buttonGrid,'Style','pushbutton','String','Add','Callback',@obj.addButtonPressed);
             obj.buttonGrid.Widths=[-1,-1];
             obj.buttonGrid.Heights=[-1];
             addlistener(obj.gridDefinitionTable,'Data','PostSet',@(~,~)obj.compUpdate);
             obj.ElectrodeDefinitionIdentifier='ElectrodeDefinition';
             obj.Heights=[-1,20];
             obj.Widths=[-1];
             
             obj.disableChanges();
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
            obj.componentChanged();
        end
        
        function enableChanges(obj)
            set(obj.gridDefinitionTable,'Enable','on');
            set(obj.deleteButton,'Visible','on');
            set(obj.addButton,'Visible','on');
        end
        
        function disableChanges(obj)
            set(obj.gridDefinitionTable,'Enable','inactive');
                        set(obj.deleteButton,'Visible','off');
            set(obj.addButton,'Visible','off');
        end
        
        function componentChanged(obj,a,b)
            comp=obj.GetComponent();
            tbl={};
            elDef=[];
            if(~isempty(comp))
                obj.enableChanges();
                elDef=comp.ElectrodeDefinition;
            else
                obj.disableChanges();
                if(obj.AvailableData.isKey(obj.ElectrodeDefinitionIdentifier))
                    elDef=obj.AvailableData(obj.ElectrodeDefinitionIdentifier).Definition;
                end

            end
            for ie=1:length(elDef)
                tbl(end+1,:)={false,elDef(ie).Type,elDef(ie).Name,elDef(ie).NElectrodes,elDef(ie).Spacing,elDef(ie).Volume};
            end
            obj.gridDefinitionTable.Data=tbl;
            if(isprop(comp,'History'))
                comp.History={};
            end
        end
        
        function compUpdate(obj)
            comp=obj.GetComponent();
            if(~isempty(comp))
                tbl=obj.gridDefinitionTable.Data;
                obj.History{end+1}={'Update',tbl};
                if(isempty(tbl))
                    comp.ElectrodeDefinition=[];
                else
                    for i=1:size(tbl,1)
                        dt(i)=struct('Type',tbl{i,2},'Name',tbl{i,3},'NElectrodes',tbl{i,4},'Spacing',tbl{i,5},'Volume',tbl{i,6});
                    end
                    comp.ElectrodeDefinition=dt;
                end
                %obj.ComponentChanged();
            end
        end
        
        
        
        function addButtonPressed(obj,~,~)
            comp=obj.GetComponent();
            tbl=obj.gridDefinitionTable.Data;
            if(isempty(tbl))
                tbl=cell(1,6);
                tbl{1,1}=false;
            else
                % tbl(end+1,:)={false,[],'',[],[],[]};
                % James changed
                tbl(end+1,:)={false,'','',[],[],[]};
            end
            obj.gridDefinitionTable.Data=tbl;
             if(isprop(comp,'History'))
                comp.History{end+1}={'Add',length(tbl)};
             end
        end
        
        function deleteButtonPressed(obj,~,~)
            comp=obj.GetComponent();
            tbl=obj.gridDefinitionTable.Data;
            if(~isempty(tbl))
                idx=[tbl{:,1}];
                tbl(idx,:)=[];
            end
            obj.gridDefinitionTable.Data=tbl;
             if(isprop(comp,'History'))
                comp.History{end+1}={'Delete',find(idx)};
             end
        end
        
        
        
    end
end


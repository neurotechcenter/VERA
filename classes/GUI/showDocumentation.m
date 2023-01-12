function  showDocumentation(comp)
%SHOWDOCUMENTATION Summary of this function goes here
%   Detailed explanation goes here
f=figure('Color','white','Name',class(comp));
grd=uix.Grid('Parent',f);
sc=uix.ScrollingPanel('Parent',grd);

h=annotation(sc,'textbox','Interpreter','latex','string','','BackgroundColor','w','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','left','VerticalAlignment','top','EdgeColor','w');


%%create configured component info:
outstring="\textbf{"+ string(class(comp))+  "} ";
outstring=[outstring "\newline "];
outstring=[outstring help('comp')];

%% create Properties table

outstring=[outstring "\textbf{Properties:} \\ "];

p=comp.GetSerializableProperties();
outstring=[outstring "\begin{tabular}{c || c | c } "];
outstring(end)=outstring(end)+ "Name & Current Value & Default Value \\ \hline \hline ";
default_templateclass=feval( class(comp) ); %creates a new empty class object to get default values

for i=1:numel(p)
    if(~isa(comp.(p{i}),'char') && isObjectTypeOf(comp.(p{i}),'Serializable'))
        outstring(end)=outstring(end)+ strrep(p{i},'_','\_') ...
        + " & " + makeStringLatexComplient(class(comp)) + " & " + makeStringLatexComplient(class(comp.(p{i}))) + " \\ ";
    else
        outstring(end)=outstring(end)+ strrep(p{i},'_','\_') ...
        + " & " + makeStringLatexComplient(jsonencode(comp.(p{i})))+ " & " + makeStringLatexComplient(jsonencode(default_templateclass.(p{i}))) + " \\ ";
    end
end
outstring(end)=outstring(end)+ " \end{tabular}";

% --- Inputs

if(~isempty(comp.Inputs))
    outstring=[outstring "\textbf{Input Configuration:} \\ "];
    outstring=[outstring "\begin{tabular}{c | c} "];
    outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";
    
    for i=1:length((comp.Inputs))
        outstring(end)=outstring(end)+ makeStringLatexComplient(comp.Inputs{i}) + " & " + makeStringLatexComplient(comp.inputMap(comp.Inputs{i})) + " \\ ";
    end
    outstring(end)=outstring(end)+ " \end{tabular}";
end

% --- Optional Inputs
if(~isempty(comp.OptionalInputs))
    outstring=[outstring "\newline "];
    outstring=[outstring "\textbf{Optional Input Configuration:} \\ "];
    outstring=[outstring "\begin{tabular}{c | c} "];
    outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";

    for i=1:length((comp.OptionalInputs))
        outstring(end)=outstring(end)+ makeStringLatexComplient(comp.OptionalInputs{i}) + " & " + makeStringLatexComplient(comp.optionalinputMap(comp.OptionalInputs{i})) + "\\";
    end
    outstring(end)=outstring(end)+ " \end{tabular}";
end



% --- Outputs
if(~isempty(comp.Outputs))
    outstring=[outstring "\newline "];
    outstring=[outstring "\textbf{Output Configuration:} \\ "];
    outstring=[outstring "\begin{tabular}{c | c} "];
    outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";

    for i=1:length((comp.Outputs))
        outstring(end)=outstring(end)+ makeStringLatexComplient(comp.Outputs{i}) + " & " + makeStringLatexComplient(comp.outputMap(comp.Outputs{i})) + "\\";
    end
    outstring(end)=outstring(end)+ " \end{tabular}";
end
% ----- add user description for component ---- 


h.String = outstring;
end


function str=makeStringLatexComplient(str)
        str=strrep(str,'_','\_');
        if(length(str) > 80)
            %str=strrep(str,',',',\\');
            str="!!...too long...!!";
        end
        %str=strrep(str,'"',"''");
        %str=strrep(str,'[','');
        %str=strrep(str,']','');
        %str=strrep(str,',','');
        %str=strrep(str,'-','');
        %str=strrep(str,'"','');
end


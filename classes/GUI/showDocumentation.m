function  showDocumentation(comp)
%SHOWDOCUMENTATION Creates a figure which displays all information from an
%AComponent class
%see also AComponent
f=figure('Color','white','Name',class(comp));
grd=uix.VBox('Parent',f);




%%create configured component info:
outstring="\textbf{"+ string(class(comp))+  "} ";
outstring=[outstring "\newline "];
outstring=[outstring help('comp')];

annotation(uix.ScrollingPanel('Parent',grd),'textbox','Interpreter','latex','string','','BackgroundColor','w','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','left','VerticalAlignment','top','EdgeColor','w', ...
                'String',outstring);

%% create Properties table

default_templateclass=feval( class(comp) ); 
outstring= "\textbf{Properties:} \\ ";

 p=comp.GetSerializableProperties();
outstring=[outstring "\begin{tabular}{c || c | c } "];
outstring(end)=outstring(end)+ "Name & Current Value & Default Value \\ \hline \hline ";
% default_templateclass=feval( class(comp) ); %creates a new empty class object to get default values

for i=1:numel(p)
    if(~isa(comp.(p{i}),'char') && isObjectTypeOf(comp.(p{i}),'Serializable'))
        outstring(end)=outstring(end)+ makeStringLatexComplient(p{i}) ...
        + " & " + makeStringLatexComplient(class(comp)) + " & " + makeStringLatexComplient(class(comp.(p{i}))) + " \\ ";
    else
        outstring(end)=outstring(end)+ makeStringLatexComplient(p{i}) ...
        + " & " + makeStringLatexComplient(jsonencode(comp.(p{i})))+ " & " + makeStringLatexComplient(jsonencode(default_templateclass.(p{i}))) + " \\ ";
    end
end
outstring(end)=outstring(end)+ " \end{tabular}";


annotation(uix.ScrollingPanel('Parent',grd),'textbox','Interpreter','latex','string','','BackgroundColor','w','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','left','VerticalAlignment','top','EdgeColor','w', ...
                'String',outstring);


% --- Inputs

if(~isempty(comp.Inputs))
    outstring="\textbf{Input Configuration:} \\ ";
    outstring=[outstring "\begin{tabular}{c | c} "];
    outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";
    
    for i=1:length((comp.Inputs))
        outstring(end)=outstring(end)+ makeStringLatexComplient(comp.Inputs{i}) + " & " + makeStringLatexComplient(comp.inputMap(comp.Inputs{i})) + " \\ ";
    end
    outstring(end)=outstring(end)+ " \end{tabular}";
annotation(uix.ScrollingPanel('Parent',grd),'textbox','Interpreter','latex','string','','BackgroundColor','w','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','left','VerticalAlignment','top','EdgeColor','w', ...
                'String',outstring);
end

% --- Optional Inputs
if(~isempty(comp.OptionalInputs))
    outstring= "\newline ";
    outstring=[outstring "\textbf{Optional Input Configuration:} \\ "];
    outstring=[outstring "\begin{tabular}{c | c} "];
    outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";

    for i=1:length((comp.OptionalInputs))
        outstring(end)=outstring(end)+ makeStringLatexComplient(comp.OptionalInputs{i}) + " & " + makeStringLatexComplient(comp.optionalinputMap(comp.OptionalInputs{i})) + "\\";
    end
    outstring(end)=outstring(end)+ " \end{tabular}";
annotation(uix.ScrollingPanel('Parent',grd),'textbox','Interpreter','latex','string','','BackgroundColor','w','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','left','VerticalAlignment','top','EdgeColor','w', ...
                'String',outstring);
end



% --- Outputs
if(~isempty(comp.Outputs))
    outstring= "\newline ";
    outstring=[outstring "\textbf{Output Configuration:} \\ "];
    outstring=[outstring "\begin{tabular}{c | c} "];
    outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";

    for i=1:length((comp.Outputs))
        outstring(end)=outstring(end)+ makeStringLatexComplient(comp.Outputs{i}) + " & " + makeStringLatexComplient(comp.outputMap(comp.Outputs{i})) + "\\";
    end
    outstring(end)=outstring(end)+ " \end{tabular}";
annotation(uix.ScrollingPanel('Parent',grd),'textbox','Interpreter','latex','string','','BackgroundColor','w','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','left','VerticalAlignment','top','EdgeColor','w', ...
                'String',outstring);
end



end


function str=makeStringLatexComplient(str)
        str=strrep(str,'_','\_');
end


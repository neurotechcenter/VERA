function  showDocumentation(comp)
%SHOWDOCUMENTATION Summary of this function goes here
%   Detailed explanation goes here
f=figure('Color','white','Name',class(comp));
grd=uix.Grid('Parent',f);
h=annotation(grd,'textbox','Interpreter','latex','string','','BackgroundColor','w','FontSize',15,...
                'units','normalized','Position',[0 0 1 1],'HorizontalAlignment','left','VerticalAlignment','top','EdgeColor','w');


%%create configured component info:
outstring=["\textbf{ "+ string(class(comp))+  "} "];
outstring=[outstring "\newline "];
outstring=[outstring "Input Configuration: \\ "];
outstring=[outstring "\begin{tabular}{c | c} "];
outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";

for i=1:length((comp.Inputs))
    outstring(end)=outstring(end)+ comp.Inputs{i} + " & " + comp.inputMap(comp.Inputs{i}) + "\\";
end
outstring(end)=outstring(end)+ "\end{tabular}";


% --- Optional Inputs
outstring=[outstring "\newline "];
outstring=[outstring "Optional Input Configuration: \\ "];
outstring=[outstring "\begin{tabular}{c | c} "];
outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";

for i=1:length((comp.OptionalInputs))
    outstring(end)=outstring(end)+ comp.OptionalInputs{i} + " & " + comp.optionalinputMap(comp.OptionalInputs{i}) + "\\";
end
outstring(end)=outstring(end)+ "\end{tabular}";

% --- Outputs
outstring=[outstring "\newline "];
outstring=[outstring "Output Configuration: \\ "];
outstring=[outstring "\begin{tabular}{c | c} "];
outstring(end)=outstring(end)+ "Name & Type \\ \hline \hline ";

for i=1:length((comp.Outputs))
    outstring(end)=outstring(end)+ comp.Outputs{i} + " & " + comp.outputMap(comp.Outputs{i}) + "\\";
end
outstring(end)=outstring(end)+ "\end{tabular}";

% ----- add user description for component ---- 


h.String = outstring;
end

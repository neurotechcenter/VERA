function [code,lut]=loadLUTFile(lutfile)
%loadLUTFile - load Freesurfer LUT file 

    try
    [code,lut]=read_fscolorlut(lutfile);
    catch %not a fs color lut
        [X,a,b]=importdata(lutfile); %we assume 1 is the ID, and 3 is the name
        code=[];
        lut={};
        for i=2:length(X.textdata)
            code(end+1)=str2num(X.textdata{i,1});
            lut{end+1}=X.textdata{i,3};
        end
    end
end


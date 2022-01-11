function [BA,labels] = findBrodmanLabel(data,jarFile,tempFolder)
%FINDBRODMANLABEL Summary of this function goes here
%   jarFile is assumed to be correct path 

writematrix(data,fullfile(tempFolder,'data.csv'),'Delimiter','\t');

%java -cp talairach.jar org.talairach.ExcelToTD 2, data.txt
system(['java -cp ' jarFile ' org.talairach.ExcelToTD 4:11, ' fullfile(tempFolder,'data.csv')]);
fid = fopen(fullfile(tempFolder,'data.csv.td'),'r');
tline = fgetl(fid);
i=1;
while ischar(tline)
    string_split=split(strtrim(tline),char(9));
    BA_id=find(contains(string_split,'Brodmann'));
    if(isempty(BA_id))
        BA{i}='Unknown';
    else
        BA{i}=strtrim(string_split{BA_id});
    end
    i=i+1;
    tline = fgetl(fid);
end





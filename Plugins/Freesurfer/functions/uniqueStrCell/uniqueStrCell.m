function out=uniqueStrCell(inputStrCell)
% This function 'uniqueStrCell' performs 'UNIQUE' for cell array of string.
% The output cell 'out' will include only string cells and numeric cells converted to strings
% , and exclude NaN and empty cells.
% Example: 
% inputStrCell={'ek','wekf', 29, NaN, [],'we'};
% out = uniqueStrCell(inputStrCell);
% >> out = {'ek'    'we'    'wekf'    '29'}
%
% Acknowledgement: 
% This function greatly benefits from Jan Simon's comments. The
% previous version was errorful. 
% See 'unique' for more information
%Weirong Chen   Apr-14-2014
out=[];
if nargin<1, display('Not enough input argument!'); return;end;
A=cellfun('isclass', inputStrCell, 'char'); 
B=cellfun(@isnumeric, inputStrCell); 
C=cellfun(@isnan, inputStrCell,'UniformOutput',false);
C=logical(cell2mat(cellfun(@sum, C,'UniformOutput',false)));
D=cellfun(@isempty, inputStrCell);
numCell = cellfun(@num2str,inputStrCell(logical(B-C-D)),'UniformOutput',false);
numCell = unique(numCell);
strCell = unique(inputStrCell(A));
out = [strCell numCell];

function [status,cmdout] = systemWSL(cmd,varargin)
%SYSTEMWSL Summary of this function goes here
%   Detailed explanation goes here
[status, cmdout]=system(['bash -c ''' cmd ''''],varargin{:});
end


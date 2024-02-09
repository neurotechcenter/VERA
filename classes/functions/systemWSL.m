function [status,cmdout] = systemWSL(cmd,varargin)
%systemWSL - make a system call through WSL subsystem
% [status, cmdout]=system(['bash -c "' cmd '"'],varargin{:}); % original
[status, cmdout]=system(['bash -c ''' cmd ''''],varargin{:});
end


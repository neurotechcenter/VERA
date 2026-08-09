function fig = scrollableErrordlg(message, titleStr)
%scrollableErrordlg Resizable, scrollable error dialog.
%   Drop-in replacement for errordlg(message, titleStr) for messages that
%   can be arbitrarily long (e.g. the full captured output of a failed
%   system() call) - errordlg's fixed-size label clips long text with no
%   way to resize the dialog or scroll to read the rest.
    if nargin < 2 || isempty(titleStr)
        titleStr = 'Error';
    end
    if ischar(message)
        lines = strsplit(message, newline);
    elseif iscell(message)
        lines = message;
    else
        lines = strsplit(char(message), newline);
    end

    fig = figure('Name', titleStr, 'NumberTitle', 'off', ...
        'MenuBar', 'none', 'ToolBar', 'none', ...
        'Resize', 'on', 'Position', [100 100 640 420]);

    uicontrol(fig, 'Style', 'edit', 'Max', 2, 'Min', 0, ...
        'Enable', 'inactive', 'HorizontalAlignment', 'left', ...
        'FontName', 'Monospaced', 'FontSize', 10, ...
        'Units', 'normalized', 'Position', [0.02 0.12 0.96 0.85], ...
        'String', lines);

    uicontrol(fig, 'Style', 'pushbutton', 'String', 'OK', ...
        'Units', 'normalized', 'Position', [0.42 0.02 0.16 0.08], ...
        'Callback', @(~,~) close(fig));
end

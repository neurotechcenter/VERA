function moveFigureOnScreen(fig)
% moveFigureOnScreen - Ensures that a figure is fully on screen
%
% This function ensures that the specified figure is on screen. If not, its
% position will be adjusted.
%
% Syntax:
%           uiw.utility.moveFigureOnScreen(fig)
%
% Inputs:
%           fig - figure
%
% Outputs:
%           none
%
%
% Notes: It is preferred (and optimized) to have figure Units in pixels.
%

% Copyright 2018-2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 445 $  $Date: 2019-03-26 10:56:10 -0400 (Tue, 26 Mar 2019) $
% ---------------------------------------------------------------------



if strcmp(fig.Units,'pixels')
    
    % Get the corners of each screen
    g = groot;
    screenPos = g.MonitorPositions;
    screenCornerA = screenPos(:,1:2);
    screenCornerB = screenPos(:,1:2) + screenPos(:,3:4) - 1;
    
    % In case menu/toolbar are turned on after this runs, we
    % may want a buffer
    titleBarHeight = 0;
    
    % Get the corners of the figure (bottom left and top right)
    figPos = fig.OuterPosition;
    figCornerA = figPos(1:2);
    figCornerB = figPos(1:2) + figPos(:,3:4) - 1;
    
    % Are the corners on any screen?
    aIsOnScreen = all( figCornerA >= screenCornerA & ...
        figCornerA <= screenCornerB, 2 );
    bIsOnScreen = all( figCornerB >= screenCornerA & ...
        figCornerB <= screenCornerB, 2);
    
    % Are corners on a screen?
    
    % Are both corners fully on any screen?
    if any(aIsOnScreen) && any(bIsOnScreen)
        % Yes - do nothing
        
    elseif any(bIsOnScreen)
        % No - only upper right corner is on a screen
        
        % Calculate the adjustment needed, and make it
        figAdjust = max(figCornerA, screenCornerA(bIsOnScreen,:)) ...
            - figCornerA;
        figPos(1:2) = figPos(1:2) + figAdjust;
        
        % Ensure the upper right corner still fits
        figPos(3:4) = min(figPos(3:4), ...
            screenCornerB(bIsOnScreen,:) - figPos(1:2) - [0 titleBarHeight] + 1);
        
        % Move the figure
        fig.OuterPosition = figPos;
        
    elseif any(aIsOnScreen)
        % No - only lower left corner is on a screen
        
        % Calculate the adjustment needed, and make it
        figAdjust = min(figCornerB, screenCornerB(aIsOnScreen,:)) ...
            - figCornerB;
        figPos(1:2) = max( screenCornerA(aIsOnScreen,:),...
            figPos(1:2) + figAdjust );
        
        % Ensure the upper right corner still fits
        figPos(3:4) = min(figPos(3:4), ...
            screenCornerB(aIsOnScreen,:) - figPos(1:2) - [0 titleBarHeight] + 1);
        
        % Move the figure
        fig.OuterPosition = figPos;
        
    else
        % No - Not on any screen
        
        % This is slower, but uncommon anyway
        movegui(fig,'onscreen');
        
    end %if any( all(aIsOnScreen,2) & all(bIsOnScreen,2) )
    
else
    % This is slower, but uncommon anyway
    movegui(fig,'onscreen');
end
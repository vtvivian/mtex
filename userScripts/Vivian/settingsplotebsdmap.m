function settingsplotebsdmap(setSave)
% set up ebsd map plot settings
% Vivian Tong NPL, for MTEX 2023 Workshop
% supplied for information only, no guarantee that any of this is correct
% or can be transferred to a different system.

if setSave
    %set up figure scaling so that the exported figures are monitor size-independent
    screenExtend = get(0,'MonitorPositions');
    figSize1 = screenExtend(1,3:4) - [0,120]; % [1536 768]
    screenScaleFac=([1920 960]*0.8)./figSize1; % figure size matches match 'large' figure for a [1920 1080] pixel screen
    setMTEXpref('figSize',max(screenScaleFac)); %
else
    setMTEXpref('figSize','large'); % optimise for screen display only
end

setMTEXpref('outerPlotSpacing',70);
setMTEXpref('showCoordinates','on');

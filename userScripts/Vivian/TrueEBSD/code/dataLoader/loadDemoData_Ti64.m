CS = {'notIndexed',...
    crystalSymmetry('6/mmm', [3 3 4.7], 'X||a*', 'Y||b', 'Z||c*', 'mineral', 'Titanium', 'color', [0.53 0.81 0.98]),...
    crystalSymmetry('m-3m', [3.3 3.3 3.3], 'mineral', 'Titanium-beta', 'color', [0.56 0.74 0.56])};
pC = plottingConvention(vector3d.Z,-vector3d.X);

if ~isdeployed
    ebsdFileIn = fullfile(cd,"..","Data\Ti-64","Ti-64_EBSD.ctf");    
    trueImgFileIn = fullfile(cd,"..","Data\Ti-64","Ti-64_BSE.tif");
    interImg1FileIn = fullfile(cd,"..","Data\Ti-64","Ti-64_FF-FSE.tif");
    interImg2FileIn = fullfile(cd,"..","Data\Ti-64","Ti-64_NF-FSE.tif");
else
    [f,p]=uigetfile('*.*','Select File Ti-64_EBSD.ctf');
    ebsdFileIn = fullfile(p,f);
    [f,p]=uigetfile('*.*','Select File Ti-64_BSE.tif');
    trueImgFileIn = fullfile(p,f);
    [f,p]=uigetfile('*.*','Select File Ti-64_FF-FSE.tif');
    interImg1FileIn = fullfile(p,f);
    [f,p]=uigetfile('*.*','Select File Ti-64_NF-FSE.tif');
    interImg2FileIn = fullfile(p,f);
    %TEMPORARY FIX - longer term solution is to remove the need for a
    %loadDemoData_dataName script in deployed app
end
ebsd = EBSD.load(ebsdFileIn,CS,'interface','ctf');
ebsd = gridify(rotate(ebsd,reflection(xvector),'keepEuler'));
ebsd.plottingConvention = pC;
trueImg = imread(trueImgFileIn);
interImg1 = imread(interImg1FileIn);
interImg2 = imread(interImg2FileIn);

% create distortedImg objects and order them from most to least
% distorted
% distortionName inputs are w.r.t the (n+1)th image - i.e. the
% distortions will stack on top of each other
disImgs{1} = distortedImg('bc','drift',ebsd, 'mapPlottingConvention', pC, 'highContrast',1,'edgePadWidth',1);
disImgs{2} = distortedImg(interImg2,'shift', 'dxy',0.2, 'highContrast',1,'edgePadWidth',1);
disImgs{3} = distortedImg(interImg1,'tilt', 'dxy',0.2, 'highContrast',1,'edgePadWidth',1);
disImgs{4} = distortedImg(trueImg,'true', 'dxy',0.2, 'highContrast',1,'edgePadWidth',1);

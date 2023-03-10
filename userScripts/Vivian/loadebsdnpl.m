function [ebsd, CSOut] = loadebsdnpl(semName, ebsdFilePath, CSIn)
% Load NPL EBSD data into MTEX and set coordinate conventions according to
% SEM and EBSD manufacturer
% CSin is the standard mtex variable for crystal symmetry and can be created
% using the EBSD import wizard
% Vivian Tong NPL, for MTEX 2023 Workshop
% supplied for information only, no guarantee that any of this is correct
% or can be transferred to a different system.

switch semName
    case 'Supra'        
        % conventions specific to Supra SEM / EDAX EBSD system
        setMTEXpref('xAxisDirection','north');
        setMTEXpref('zAxisDirection','outofPlane');       
        
        cs_alignment = [{'X||a'}, {'Y||b*'}, {'Z||c*'}];
        
    case 'Auriga'        
        % conventions specific to Auriga SEM / OxInst-Sym2 EBSD system
        setMTEXpref('xAxisDirection','west');
        setMTEXpref('zAxisDirection','outofPlane');
        
        cs_alignment = [{'X||a*'}, {'Y||b'}, {'Z||c*'}];
    otherwise        
        error('unknown SEM+EBSD system, can''t define SEM axes!');        
end
%in both cases, define bAxisDirection - affects IPF key colours and inverse
%pole figure plotting orientations, but not map coordinates.
setMTEXpref('bAxisDirection','east');

% recreate CS (create CSOut) to reflect EDAX crystal2cartesian
% convention
CSOut=cell(1,numel(CSIn));
for p=1:numel(CSIn) %loop through all phases
    if strcmpi('notIndexed',CSIn{p})
        CSOut{p}=CSIn{p};
    else
        % back-calculation of the abc unit cell lengths from CSIn{p}.axes is
        % taken from '\mtex\interfaces\import_wizard\private\pageCS.m'
        % round to 10dp to avoid floating point error differences leading to 
        % errors later in '\mtex\geometry\@crystalSymmetry\private\calcAxis.m'
        CSOut{p} = crystalSymmetry(CSIn{p}.pointGroup, round(norm(CSIn{p}.axes(:))',10), cs_alignment{:}, 'mineral', CSIn{p}.mineral, 'color', CSIn{p}.color);
    end    
end

% load ebsd variable
switch semName
    case 'Supra'        
        % create an EBSD variable containing the data
        ebsd = EBSD.load(ebsdFilePath,CSOut,'interface','ang',...
            'convertSpatial2EulerReferenceFrame','setting 2');                
    case 'Auriga'
        % create an EBSD variable containing the data
        % the EBSD coordinate correction does not require
        % 'convertSpatial2EulerReferenceFrame', but we do need to flip the
        % ctf file map scan X-coodinates) as they don't match the SEM
        % spatial coordinates
        
        %first find out whether we have a ctf, crc or cpr file:
        [~,~,ext]=fileparts(ebsdFilePath);
        if strcmp(ext,'.cpr'); ext='.crc'; end
        ebsd = EBSD.load(ebsdFilePath,CSIn,'interface',ext(2:end));
        ebsd = rotate(ebsd,reflection(xvector),'keepEuler'); %CTF recorded x-values match the beam scan coordinates, not the SEM spatial coordinates
    otherwise        
        error('unknown SEM+EBSD system, can''t load EBSD data!');        
end
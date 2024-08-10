%% Import EBSD data
pC = plottingConvention(vector3d.Z,-vector3d.X);

ebsd = gridify(rotate(...
    loadEBSD_h5oina(fullfile(cd,"..","Data\copper\ID29","id29.h5oina")),...
    reflection(xvector),'keepEuler'));
ebsd.plottingConvention = pC;


%% Read SEM images from h5oina file
% images commented out are included for completeness but not actually used
% for TrueEBSD
fsd1B = rescale(im2double(cat(3,ebsd.opt.Images.Lower_Centre_19, ...
    ebsd.opt.Images.Lower_Left_19, ...
    ebsd.opt.Images.Lower_Right_19))); 

% fsd1T = im2double(mean(cat(3,ebsd.opt.Images.Upper_Left_19, ...
    % ebsd.opt.Images.Upper_Right_19),3));

% fsd1 = rescale(im2double(cat(3,ebsd.opt.Images.Lower_Centre_19, ...
%     ebsd.opt.Images.Lower_Left_19, ...
%     ebsd.opt.Images.Lower_Right_19,ebsd.opt.Images.Upper_Left_19, ...
%     ebsd.opt.Images.Upper_Right_19))); 
% 
% fsd2B = rescale(im2double(cat(3,ebsd.opt.Images.Lower_Centre_20, ...
%     ebsd.opt.Images.Lower_Left_20, ...
%     ebsd.opt.Images.Lower_Right_20))); 
% 
% fsd2T = im2double(mean(cat(3,ebsd.opt.Images.Upper_Left_20, ...
%     ebsd.opt.Images.Upper_Right_20),3));

% fsd2 = rescale(im2double(cat(3,ebsd.opt.Images.Lower_Centre_20, ...
%     ebsd.opt.Images.Lower_Left_20, ...
%     ebsd.opt.Images.Lower_Right_20,ebsd.opt.Images.Upper_Left_20, ...
%     ebsd.opt.Images.Upper_Right_20))); 

% fsd3B = rescale(im2double(cat(3,ebsd.opt.Images.Lower_Centre_21, ...
%     ebsd.opt.Images.Lower_Left_21, ...
%     ebsd.opt.Images.Lower_Right_21))); 
% 
% fsd3T = im2double(mean(cat(3,ebsd.opt.Images.Upper_Left_20, ...
%     ebsd.opt.Images.Upper_Right_20),3));
% 
% fsd3 = rescale(im2double(cat(3,ebsd.opt.Images.Lower_Centre_21, ...
%     ebsd.opt.Images.Lower_Left_21, ...
%     ebsd.opt.Images.Lower_Right_21,ebsd.opt.Images.Upper_Left_21, ...
%     ebsd.opt.Images.Upper_Right_21))); 


bse1 = rescale(im2double(ebsd.opt.Images.ABSinner_0deg));
% bse2 = rescale(im2double(ebsd.opt.Images.CBS_0deg_immersion));
% bse3 = rescale(im2double(ebsd.opt.Images.CBS_0deg_immersion_20kV));
% bse4 = rescale(im2double(ebsd.opt.Images.CBSab_0deg));
% bse5 = rescale(im2double(ebsd.opt.Images.T1_0deg));
% bse6 = rescale(im2double(ebsd.opt.Images.T1_0deg_immersion));
% bse7 = rescale(im2double(ebsd.opt.Images.T1_0deg));



%% Check images
% flatsigma = 10;
% imflatfield(fsd1B,flatsigma)
%{
figure; tiledlayout('flow','TileSpacing','tight');
% nexttile; imagesc(fsd1B); axis image;
% nexttile; imagesc(fsd1T); axis image; 
% nexttile; imagesc(fsd2B); axis image;
% nexttile; imagesc(fsd2T); axis image; 
% nexttile; imagesc(fsd3B); axis image;
% nexttile; imagesc(fsd3T); axis image; 
nexttile; imagesc(bse1); axis image; 
nexttile; imagesc(bse2); axis image; 
nexttile; imagesc(bse3); axis image;
% nexttile; imagesc(bse4); axis image;
% nexttile; imagesc(bse5); axis image; 
% nexttile; imagesc(bse6); axis image;
% nexttile; imagesc(bse7); axis image; 
colormap gray;
%}

%% Image preprocessing
% inspect and choose one
%{
figure; tiledlayout('flow');
nexttile; imagesc(fsd2T); axis image; xlim([939.3 1197.8]); ylim([664.5 1009.2]);
nexttile; imagesc(imboxfilt(fsd2T,3)); axis image; xlim([939.3 1197.8]); ylim([664.5 1009.2]);
nexttile; imagesc(imboxfilt(fsd2T,5)); axis image; xlim([939.3 1197.8]); ylim([664.5 1009.2]);
nexttile; imagesc(imboxfilt(fsd2T,7)); axis image; xlim([939.3 1197.8]); ylim([664.5 1009.2]);
colormap gray;
%}

fsd1a = imboxfilt(fsd1B,5);

bse1a = imboxfilt(nthroot(bse1,0.1),5);
bse1b = double(imbinarize(imboxfilt(bse1,3),0.8));
%% construct distortedImg list
disImgs{1} = distortedImg('bc','shift-drift', ebsd, 'mapPlottingConvention', pC, 'highContrast',1,'edgePadWidth',3);
disImgs{end+1} = distortedImg(fsd1a,'tilt', 'dxy', double(ebsd.opt.Images.Header.X_Step), 'highContrast',1,'edgePadWidth',3); % 
disImgs{end+1} = distortedImg(bse1a,'true', 'dxy', double(ebsd.opt.Images.Header.X_Step), 'highContrast',1,'edgePadWidth',3); % 
disImgs{end+1} = distortedImg(bse1b,'true', 'dxy', double(ebsd.opt.Images.Header.X_Step), 'highContrast',0,'edgePadWidth',1); % BSE but with pores contrast
% 
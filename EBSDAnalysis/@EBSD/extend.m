function [xmin, xmax, ymin, ymax] = extend(ebsd)
% function wrapper for extent(ebsd) to maintain compatibility after a
% spelling error fix
[xmin, xmax, ymin, ymax] = extent(ebsd);
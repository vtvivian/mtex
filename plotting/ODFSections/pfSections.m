classdef pfSections < ODFSections

  properties
    h1        % the pole figure which is splitted up
    h2        %
    omega
    sR
    referenceField
  end

  properties (Hidden=true)
    maxOmega
  end

  methods

    function oS = pfSections(CS1,CS2,varargin)

      oS = oS@ODFSections(CS1,CS2);

      oS.h1 = Miller(0,0,1,'hkl',CS1); % c*
      oS.h2 = Miller(1,0,0,'uvw',CS1); % a

      oS.maxOmega = get_option(varargin,'maxOmega',2*pi / CS1.nfold(oS.h1));
      if angle(oS.h1,-oS.h1) < 1e-2
        oS.sR = CS2.fundamentalSector('upper',varargin{:});
      else
        oS.sR = CS2.fundamentalSector(varargin{:});
      end

      % get sections
      oS.omega = linspace(0,oS.maxOmega,1+get_option(varargin,'sections',6));
      oS.omega(end) = [];
      oS.omega = get_option(varargin,'omega',oS.omega,'double');

      oS.referenceField = @(r) S2VectorField.oneSingularity;
      %oS.referenceField = @(r) pfSections.polarField(r);

    end

    function ori = makeGrid(oS,varargin)

      oS.plotGrid = plotS2Grid(oS.sR,varargin{:});
      oS.gridSize = (0:numel(oS.omega)) * length(oS.plotGrid);

      ori = orientation.nan(oS.plotGrid.size(1),oS.plotGrid.size(2),numel(oS.omega),oS.CS1,oS.CS2);
      for iOmega = 1:numel(oS.omega)

        r2 = oS.vectorField(oS.plotGrid,oS.omega(iOmega));
        ori(:,:,iOmega) = reshape(orientation.map(oS.h1,oS.plotGrid,oS.h2,r2),size(oS.plotGrid));

      end

    end

    function n = numSections(oS)
      n = numel(oS.omega);
    end

    function [r,secPos] = project(oS,ori,varargin)

      % maybe this can be done more efficiently
      ori = ori.symmetrise('proper').';

      % determine pole figure position
      r = ori * oS.h1;

      % determine omega angle
      rF = ori * oS.h2;
      vF = vectorField(oS,r);
      omega = angle(vF,rF,r);

      % this builds a list
      bounds = sort(unique([oS.omega - oS.tol,oS.omega + oS.tol]));
      [~,secPos] = histc(omega,bounds); %#ok<*PROPLC>
      secPos(iseven(secPos)) = -1;
      secPos = (secPos + 1)./2;

    end

    function ori = iproject(oS,rho,theta,iOmega)
      r1 = vector3d.byPolar(theta,rho);
      r2 = oS.vectorField(r1,oS.omega(iOmega));

      ori = orientation.map(oS.h1,r1,oS.h2,r2);
    end

    function h = plotSection(oS,ax,sec,v,data,varargin)

      % plot data
      h = plot(v,data{:},oS.sR,'TR',[int2str(oS.omega(sec)./degree),'^\circ'],...
        'parent',ax,varargin{:},'doNotDraw');

      wasHold = ishold(ax);
      hold(ax,'on');
      r = equispacedS2Grid(oS.sR,'resolution',15*degree);
      vF = oS.vectorField(r,oS.omega(sec));
      quiver(r,vF,'parent',ax,'doNotDraw','arrowSize',0.1,'color',0.7*[1 1 1],'HitTest','off');
      if ~wasHold, hold(ax,'off'); end

    end
    
    function h = quiverSection(oS,ax,sec,v,data,varargin)

      % plot data
      h = quiver(v,data{:},oS.sR,'TR',[int2str(oS.omega(sec)./degree),'^\circ'],...
        'parent',ax,varargin{:},'doNotDraw');

    end

    function vF = vectorField(oS,r,omega)


      vF = oS.referenceField.eval(r);

      if nargin == 3
        vF = rotation.byAxisAngle(r,omega) .* vF;
      end

    end


  end     

end

% testing code
% r = equispacedS2Grid('resolution',20*degree)
% quiver(r,vector3d(vF),'arrowSize',0.1)

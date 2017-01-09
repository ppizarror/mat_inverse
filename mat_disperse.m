function [vr,varargout] = mat_disperse(thk,dns,cvp,cvs,freq,flag,varargin)

% Usage:
% 		vr = mat_disperse(thk,dns,cvp,cvs,freq)
% 		[vr,z,r] = mat_disperse(thk,dns,cvp,cvs,freq)
% 		[vr,z,r,dvrvs] = mat_disperse(thk,dns,cvp,cvs,freq)
% 		[vr,z,r,dvrvs,vre,dvrevs] = mat_disperse(thk,dns,cvp,cvs,freq,offsets)
% 		[vr,z,r,dvrvs,vre,dvrevs,ur,uy] = mat_disperse(thk,dns,cvp,cvs,freq,offsets)
%
% This function solves the eigenvalue problem for Rayleigh waves in an elastic, 
% vertically heterogeneous halfspace and returns the modal phase
% velocities. The user may also choose to calculate:
%
%   - displacment-stress vectors,
%
%   - partial derivatives of the modal Rayleigh phase velocities with respect 
%   to the shear and compression wave velocities of each layer, 
%
%   - the effective Rayleigh phase velocities resulting from the superposition
%   of the modal phase velocities and their partial derivatives, and
%
%   - the Green's function of the Rayleigh wave displacement field using the concept
%   of mode superposition.
%
% The algorithms are based on:
%
% Xiaofei Chen (1993). 'A systematic and efficient method of computing
% normal modes for multilayered half-space', GJI.
%
% Hisada, Y., (1994). "An Efficient Method for Computing Green's Functions for
% a Layered Half-Space with Sources and Receivers at Close Depths," Bulletin of
% the Seismological Society of America, Vol. 84, No. 5, pp. 1456-1472.
%
% Lai, C.G., (1998). "Simultaneous Inversion of Rayleigh Phase Velocity and
% Attenuation for Near-Surface Site Characterization," Ph.D. Dissertation,
% Georgia Institute of Technology.
%
% List of required input parameters:
%	thk:	vector of N layer thicknesses
%	dns:	vector of N+1 layer mass densities
%	cvp:	vector of N+1 complex-valued layer compression wave velocities
%	cvs:	vector of N+1 complex-valued layer shear wave velocities
%	freq:	vector of M frequencies in Hz
%
% List of optional input parameters:
%	offsets:	vector of P offsets from the source position
%	Fx,Fy,Fz:   scalar source magnitudes in x, y, and z directions
%	Phi:		scalar orientation of source (in radians)
%	s_depth:	scalar depth of source
%	r_depth:	scalar depth of receiver
%
% List of required output parameters:
%	vr:		matrix of modal phase velocities (M by MAXROOT)
%
% List of optional output parameters:
%	z:		matrix of depths (NUMPOINTS by M)
%	r:		matrix of displacement-stress vectors (M by MAXROOT by NUMPOINTS by 4)
%	dr:		matrix of displacement-stress derivatives (M by MAXROOT by NUMPOINTS by 2)
%	U:		matrix of group velocities (M by MAXROOTS)
%	zdvrvs:	matrix of partial derivatives at individual depths (M by MAXROOT by NUMPOINTS)
%	zdvrvp:	matrix of partial derivatives at individual depths (M by MAXROOT by NUMPOINTS)
%	dvrvs:	matrix of partial derivatives for each layer (M by MAXROOT by N+1)
%	dvrvp:	matrix of partial derivatives for each layer (M by MAXROOT by N+1)
%	vre:	matrix of effective vertical phase velocities (M by P)
%	dvrevs:	matrix of partial derivatives of vre for each layer (M by P by N+1)
%	dvrevp:	matrix of partial derivatives of vre for each layer (M by P by N+1)
%	ur:		matrix of horizontal Rayleigh wave displacements (M by P)
%	uy:		matrix of vertical Rayleigh wave displacements (M by P)
%
% Modification history:
% 03/25/2015: Yiran Ma (Caltech)
%               (1) Add Love wave dispersion 
%               (2) Correct for the error in the integration of partial
%               derivatives respect to layer (partial.m).
%               (3) Correct for high frequency eigenvector calculation of fundamental
%               mode rayleigh wave (disp_stress.m)
%               (4) Fast the process of eigenvector by search for the
%               depths needs dense sampling first
%
% Copyright 2003 by Glenn J. Rix and Carlo G. Lai
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%google
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


% Establish global parameters

% Tolerance for declaring a zero
global TOL; TOL = 1e-2;
% Assumed maximum number of modes at any frequency
global MAXROOT; MAXROOT = 1;
% Maximum number of increments to search between vrmin and vrmax
global NUMINC; NUMINC = 200;
% Number of points (depths) for calculating displacement-stress vectors (eigenfunctions)
global NUMPOINTS; NUMPOINTS = 20001; 
% Wavelength multiplier for calculating displacement-stress vectors (eigenfunctions)
global LAMBDA; LAMBDA = 10;
%
global vr_half

% Convert all input parameters to column vectors
thk = reshape(thk,length(thk),1);
dns = reshape(dns,length(dns),1);
cvp = reshape(cvp,length(cvp),1);
cvs = reshape(cvs,length(cvs),1);
freq = reshape(freq,length(freq),1);

% Determine the minimum and maximum body wave velocities
cvpmin = min(cvp); cvpmax = max(cvp);
cvsmin = min(cvs); cvsmax = max(cvs);


% Define the magnitudes and orientation of the source in the x, y, and z
% directions and the depth of the source and receiver. Currently, only the
% algorithm for a vertical source at the surface is implemented. See Hisada (1994)
% for other options.
Fx = 0; Fy = 0; Fz = 1.0; Phi = 0;
s_depth = 0.0; r_depth = 0.0;

if strcmp(flag,'R')
    % Determine the minimum and maximum Rayleigh phase velocities in a
    % homogeneous half space corresponding to the minimum and maximum
    % compression and shear velocities
    vrmin = homogeneous(cvpmin,cvsmin);
    vrmax = homogeneous(cvpmax,cvsmax);
    vr_half = homogeneous(cvp(1),cvs(1)); 
    
    % Note: the following empirical rules need further study
    vrmin = 0.98*vrmin;
    vrmax = 1.00*cvsmax;
    
    % Determine the modal phase velocities
    vr = modal(freq,thk,dns,cvp,cvs,vrmin,vrmax);
elseif strcmp(flag,'L')
    vrmin = 0.5*cvsmin;
    vrmax = 1.00*cvsmax;
    
    vr = modal_love(freq,thk,dns,cvs,vrmin,vrmax);
else
    error('Input the type of wave (R or L)!');
end


% Determine the displacement-stress vectors and their derivatives with respect to depth
if (nargout >= 2)
    if strcmp(flag,'R')
        [z,r,dr] = disp_stress(freq,vr,thk,dns,cvs,cvp,Fz);
    elseif strcmp(flag,'L')
        [z,r,dr] = disp_stress_love(freq,vr,thk,dns,cvs);
    end

% Determine the energy integrals, group velocities, and the partial derivatives of the
% modal phase velocites with respect to the shear and compression wave velocities both
% at individual depths and for each layer
    if strcmp(flag,'R')
        [I1,I2,I3,U,zdvrvs,zdvrvp,zdvrrho,dvrvs,dvrvp,dvrrho] = partial(freq,vr,z,r,dr,thk,dns,cvs,cvp);
        varargout{1} = dvrvs;
        varargout{2} = dvrrho;
        varargout{3} = dvrvp;
        varargout{4} = z;
        varargout{5} = zdvrvs;
        varargout{6} = zdvrrho;
        varargout{7} = zdvrvp;
    elseif strcmp(flag,'L')
        [I1,I2,I3,U,zdvrvs,zdvrrho,dvrvs,dvrrho] = partial_love(freq,vr,z,r,dr,thk,dns,cvs);
        varargout{1} = dvrvs;
        varargout{2} = dvrrho;
        varargout{3} = z;
        varargout{4} = zdvrvs;
        varargout{5} = zdvrrho;
    end
end
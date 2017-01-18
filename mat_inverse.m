function [niter,vr_iter,vp_iter,vs_iter,dns_iter] = mat_inverse(tag,freq,vr_exp,sigma,thk,vp,vs,dns,maxiter, mu,tol_vs)
% input:
%   1. dispersion curve
%       L/R, freq, vr_exp, sigma
%   2. initial model
%       thk, vp, vs, dns
%   3. parameters control the inversion
%       maxiter, mu, tol_vs (change in vs)

nl = length(thk);
% weight matrix
w = diag(1./sigma);

% second derivative
delta = curv(nl,nl+1);
%L = [delta delta];
L = delta; 

rms = zeros(maxiter,1);

% initialize
%m0   = [vs;dns];
m0 = vs;
vp0 = vp;
vs0 = vs;
dns0 = dns;

vp_iter = zeros(nl+1,maxiter);
vs_iter = zeros(nl+1,maxiter);
dns_iter= zeros(nl+1,maxiter);
vr_iter = zeros(length(freq),maxiter);
for i=1:maxiter
        
    % calculate theoretical phase velocity and partial derivatives
    % warning: presently the code only handle 1 type of dispersion!
    [vr,dvrvs,dvrrho] = mat_disperse(thk,dns0,vp0,vs0,freq,tag);
    
    %jac = [real(squeeze(dvrvs)) real(squeeze(dvrrho))];
    jac = real(squeeze(dvrvs));
    
    % calculate the rms error
    error  = w*(vr-vr_exp);
    rms(i) = sqrt( mean(error.^2) );
    
    % least square inversion
    wjac = w * jac;
    
    b  = w * (vr_exp - vr + jac * m0);
    m1 = (wjac'*wjac + mu^2*(L'*L))\(wjac'*b);     
    
    % evaluate new model
    vs1 = m1(1:nl+1);
    vp1 = vp;
    %dns1 = m1(nl+2:nl+2+nl);
    dns1= dns;
    vr = mat_disperse(thk,dns1,vp1,vs1,freq,tag);
    error1 = w*(vr-vr_exp);
    rms1   = sqrt( mean(error1.^2) );
    
    % store the models
    vp_iter(:,i) = vp1;
    vs_iter(:,i) = vs1;
    dns_iter(:,i)= dns1;
    vr_iter(:,i) = vr(:);
    
    % check for convergence
    % only check vs ?
    diff_vs = vs1 - vs0;
    rms_vs_change = sqrt(mean(diff_vs.^2));
    
    if rms_vs_change<tol_vs || rms1 <= 1 
        break
    end
    
    m0  = m1;
    dns0= dns1;
    vp0 = vp1;
    vs0 = vs1;
end
niter = i;

end


% curvature matrix for regularization
function delta = curv(m,n)
    delta   = diag( ones(1,m),0 ) + diag(-2*ones(1,m-1), 1 ) + diag(ones(1,m-2),2);
      tmp   = zeros(m,1);
    tmp(m)  = -1; 
    tmp(m-1)=  1; 
    delta   = [delta tmp];
end


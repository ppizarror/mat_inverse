% Se crea un modelo
thk = [5.0 10.0 10.0]';
dns = [1.7 1.8 1.8 1.8]';
vs = [200 300 400 500]';
vp = [400 600 800 1000]';

% Frecuencias
freq = linspace(5,100,20)';
nfreq = length(freq);
period = 1./freq;

% Se crea la curva de dispersi�n
[vr,~,~,~,~,~]= mat_disperse(thk,dns,vp,vs,freq,'R');

% Se plotean los resultados
figure(1);
plot(freq,vr,'ro-');
xlabel('Frecuencia [${s}^{-1}]$','Interpreter','latex'); ylabel('C [$m/s$]');
title('Dispersion curve');

% Se a�ade ruido
sigma = 0.02 + zeros(nfreq,1);
err   = sigma.*randn(nfreq,1);
vr_exp= vr + err;


% Par�metros de inversi�n
maxiter = 10;  
mu = 10;
tol_vs = 0.01;

% Se crea un modelo inicial
thk1 = [5.0 10.0 10.0]';
dns1 = [1.8 1.8 1.8 1.8]';
vs1 = [350 350 350 350]';
vp1 = [700 700 700 700]';

% Se genera inversi�n
[niter,vr_iter,vp_iter,vs_iter,dns_iter] = mat_inverse('R',freq,vr_exp,sigma,thk1,vp1,vs1,dns1,maxiter,mu,tol_vs);

% Se plotea inversi�n
figure(2)
hold on;
plot(freq, vr, 'ro')
plot(freq, vr_iter(:,niter))
hold off;

vp_iter(:,niter)
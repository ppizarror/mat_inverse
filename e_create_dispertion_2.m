% Se crea un modelo
thk = [5.0 10.0 10.0]';
dns = [1.7 1.8 1.8 1.8]';
vs = [200 300 400 500]';
vp = [400 600 800 1000]';

% Frecuencias
freq = linspace(5,100,20)';
nfreq = length(freq);
period = 1./freq;

% Se crea la curva de dispersión
[vr,~,~,~,~,~]= mat_disperse(thk,dns,vp,vs,freq,'R');

% Se plotean los resultados
figure(1);
plot(freq,vr,'ro-');
xlabel('Frecuencia [${s}^{-1}]$','Interpreter','latex');
ylabel('Velocidad de Fase $(m/s)$','Interpreter','latex');
title('Curva de dispersión');

% Se añade ruido
sigma = 0.02 + zeros(nfreq,1);
err   = sigma.*randn(nfreq,1);
vr_exp= vr + err;

% Parámetros de inversión
maxiter = 10;  
mu = 10;
tol_vs = 0.01;

% Se crea un modelo inicial
thk1 = [5.0 10.0 10.0]';
dns1 = [1.8 1.8 1.8 1.8]';
vs1 = [350 350 350 350]';
vp1 = [700 700 700 700]';

% Se genera inversión
[niter,vr_iter,vp_iter,vs_iter,dns_iter] = mat_inverse('R',freq,vr_exp,sigma,thk1,vp1,vs1,dns1,maxiter,mu,tol_vs);

% Se compara curva de dispersión teórica con la experimental
h2 = figure('Name','Curva de Dispersión Teórica v/s Experimental','NumberTitle','off');
errorbar(freq,vr_exp,sigma,'ro');
hold on;
final_iteration = niter;
plot(freq,vr_iter(:,final_iteration));
xlabel('Frequency $(Hz)$','Interpreter','latex');
ylabel('Velocidad de Fase $(m/s)$','Interpreter','latex');
hold off;

% Se plotea velocidad de corte en cada profunidad
vsfinal = vs_iter(:, niter)';
vsinitial = vs';
thk = thk';
if ~isempty(vsfinal)
    cumthk = [0 cumsum(thk)]; depth = 0; velocity = vsfinal(1); middepth = []; mdl_vel = vsinitial(1);
    for j = 1:length(thk)
        depth = [depth cumthk(j+1) cumthk(j+1)]; %#ok<*AGROW>
        velocity = [velocity vsfinal(j) vsfinal(j+1)];
        mdl_vel = [mdl_vel vsinitial(j) vsinitial(j+1)];
        middepth = [middepth (cumthk(j+1)+cumthk(j))/2 (cumthk(j+1)+cumthk(j))/2 NaN];
    end
    depth = [depth sum(thk)+thk(length(thk))];
    velocity = [velocity vsfinal(length(vsfinal))];
    mdl_vel = [mdl_vel vsinitial(length(vsinitial))];
    middepth = [middepth (2*sum(thk)+thk(length(thk)))/2 (2*sum(thk)+thk(length(thk)))/2];
    j = length(vsfinal);

    h3 = figure('Name','Perfil de Velocidad de Corte','NumberTitle','off');
    plot(velocity,depth,'b', mdl_vel, depth, 'k--');
    set(gca,'YDir','reverse','XAxisLocation','top');
    set(gca,'Position',[0.13 0.05 0.775 0.815],'PlotBoxAspectRatio',[0.75 1 1]);
    xlabel('Velocidad de onda de corte $V_s$ $(m/sec)$','Interpreter','latex');
    ylabel('Profundidad $(m)$','Interpreter','latex');
    legend('Modelo inverso', 'Valor real');
end
% Poisson
poisson = [0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2];

% Vector de soluciones inicial
thk = [2 3 5 5 5 5 5]';
dns1 = [1.8 1.8 1.8 1.8 1.8 1.8 1.8 1.8]';
vs1 = [150 150 150 150 150 150 150 150]';
vp1 = vs1.*sqrt((2-2*poisson)./(1-2*poisson))';

% Parámetros de inversión
maxiter = 10;  
mu = 10;
tol_vs = 0.01;

% Curva de dispersión inicial
freq = [5.0000    5.5937    6.1875    6.7812    7.3750    7.9687    8.5625    9.1562...
    9.7500   10.3437   10.9375   11.5312   12.1250   12.7187   13.3125   14.5000   16.2812...
   18.0625   19.8438   21.6250   23.4063   25.1875   26.9688   28.7500   30.5313   32.3125...
   34.0938   34.6875   38.8438   43.0000   47.1563   51.3125   55.4688   59.6250   63.7813]';

vrexp = [301.1762  238.6665  287.9998  315.6362  228.8484  220.5404  213.8536  208.3555...
      203.7550  199.8490  199.9999  200.1355  203.5409  200.3692  200.4706  200.6486  200.8674...
  198.8817  197.2816  199.4955  198.0826  198.4000  195.8582  192.4183  191.8037  188.0000...
  183.7474  184.0415  186.7418  186.5763  160.9600  164.7148  150.6632  157.3609  160.0785]';

sigma = 0.02*vrexp;

% Se genera la inversión
[niter,vr_iter,vp_iter,vs_iter,dns_iter] = mat_inverse('R',freq,vrexp,sigma,thk,vp1,vs1,dns1,maxiter,mu,tol_vs);

% Plot and compare the experimental and theoretical dispersion curves
h2 = figure('Name','Experimental vs. Theoretical Dispersion Curves','NumberTitle','off');
errorbar(freq,vr_exp,sigma,'ro');
hold on;
final_iteration = niter;
plot(freq,vr_iter(:,final_iteration));
xlabel('Frequency (Hz)'); ylabel('Phase Velocity');
hold off;

vs_final = vs_iter(:, niter);
if ~isempty(vsfinal)
    % Plot the final shear wave velocity profile and standard deviations
    cumthk = [0 cumsum(thk)]; depth = 0; velocity = vsfinal(1); middepth = []; stdev = [];
    for j = 1:length(thk)
        depth = [depth cumthk(j+1) cumthk(j+1)];
        velocity = [velocity vsfinal(j) vsfinal(j+1)];
        middepth = [middepth (cumthk(j+1)+cumthk(j))/2 (cumthk(j+1)+cumthk(j))/2 NaN];
        stdev = [stdev vsfinal(j)-vs_stdev(j) vsfinal(j)+vs_stdev(j) NaN];
    end
    depth = [depth sum(thk)+thk(length(thk))];
    velocity = [velocity vsfinal(length(vsfinal))];
    middepth = [middepth (2*sum(thk)+thk(length(thk)))/2 (2*sum(thk)+thk(length(thk)))/2];
    j = length(vsfinal);
    stdev = [stdev vsfinal(j)-vs_stdev(j) vsfinal(j)+vs_stdev(j)];

    h3 = figure('Name','Shear Wave Velocity Profile','NumberTitle','off');
    plot(velocity,depth,'b',stdev,middepth,'b');
    set(gca,'YDir','reverse','XAxisLocation','top');
    set(gca,'Position',[0.13 0.05 0.775 0.815],'PlotBoxAspectRatio',[0.75 1 1]);
    xlabel('Shear Wave Velocity (m/sec)');
    ylabel('Depth (m)');
end
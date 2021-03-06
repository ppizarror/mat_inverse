% 1-10 sec Love wave disperion from CVM model
close all;
%addpath('/home/yma/Codes/Surf.Codes/mat_disperse');

itheo = 1;
disp_theo  = 'disp_theo.txt';
model_theo = 'CVM_basin.mdl';

%%%
% creat 1~10 s dispersion curve from CVM basin model
if itheo    
    % create synthetic dispersion curve
    period = 1:0.25:10;
    period = period(:);
    freq   = 1./period;
    nfreq= length(period);
    
    z = 0:1:40; % top of the layers
    
    % create the model
    [thk,dns,vp,vs] = create_model(z);
    
    % plot and write the model
%     figure(1)
%     plt_model_rbh(thk,dns,vp,vs,'-');
%     write_model_rbh(model_theo,thk,vp,vs,dns);
%     dlmwrite('period.txt',period,'delimiter',' ');
    
    % calculate the theoretical dispersion curve
    % Love for now!
    [vr,~,~,~,~,~]= mat_disperse(thk,dns,vp,vs,freq,'R');
    % [T_rbh,vr_rbh] = read_rbh;  % read benchmark from "rbh"
    
    % plot and write the disperion
    figure(2);
    % plot(T_rbh,vr_rbh,'ko-');
    hold on;
    plot(freq, vr,'ro-');
    xlabel('Frecuency [Hz]$'); ylabel('C');
    % legend('rbh','this code');
    title('Dispersion curve');
    hold off;
    
    dlmwrite(disp_theo,[period(:) vr(:)],'delimiter',' ','precision',5);
 
end
%%%

if ~itheo
    data   = load(disp_theo);
    period = data(:,1);
    freq   = 1./period;
    nfreq  = length(period);
    vr = data(:,2);
end

% add noise to the dispersion curve
sigma = 0.02 + zeros(nfreq,1);
err   = sigma.*randn(nfreq,1);
vr_exp= vr + err;


figure(2)
hold on;
plot(freq,vr_exp,'b.-');
hold off;

% dlmwrite(['disp_exp.txt_',num2str(sigma(1))],[period vr(:) vr_exp(:)],'delimiter',' ','precision',5);

%%%
% start the inversion!
% create initial model
% parameter for the inversion
maxiter = 10;  
mu = 10;
tol_vs = 0.01;

% initial model, 15 km
z1 = 0:1:15;
[thk1,dns1,vp1,vs1] = create_model(z1);

% make a constant shift
dns1 = 120/100 * dns1;
vp1  = 120/100 * vp1;
vs1  = 120/100 * vs1;

[niter,vr_iter,~,~,~] = mat_inverse('L',freq,vr_exp,sigma,thk1,vp1,vs1,dns1,maxiter, mu, tol_vs);

fprintf('Total number of iterations: %d \n',niter);

figure(2)
hold on;
plot( freq, vr_iter(:,niter),' ko-');

% plot the model
% [thk0,dns0,vp0,vs0] = read_model_rbh(model_theo);

% figure(4)
%plt_model_rbh(thk0,dns0,vp0,vs0,'-');
hold on;
% PLOT: INPUT MODEL
% plt_model_rbh(thk1,dns_iter(:,niter),vp_iter(:,niter),vs_iter(:,niter),'o-');
hold off;

% 
% function [T,C] = read_rbh
% % read love for now
% file = 'rbh/SLEGN.ASC';
% fid = fopen(file);
% fgetl(fid);
% m = textscan(fid,'%d %d %f %f %f %f %f %f');
% fclose(fid);
% T = m{3};
% C = m{5};
% end


function [thk,rho,vp,vs] = create_model(z)

    % model mode=1 interpola, 0 carga datos
    model_mode = 1;

    if model_mode
        % z is top of each layer, except the last value
        % create the mid points
        z1   = z(1:end-1);
        z2   = z(2:end);
        zmid = (z1 + z2)./2;

        vp_file = 'vp_basin.grd';
        vs_file = 'vs_basin.grd';
        rho_file= 'rho_basin.grd';

        vp_data = load(vp_file);
        vs_data = load(vs_file);
        rho_data= load(rho_file);

        vp = interp1(vp_data(:,1),vp_data(:,2),zmid);
        vs = interp1(vs_data(:,1),vs_data(:,2),zmid);
        rho= interp1(rho_data(:,1),rho_data(:,2),zmid);

        % vp = vp_data(:,2);
        % vs = vs_data(:,2);
        % rho= rho_data(:,2);

        thk= z2-z1;
        thk= thk(:);
        vp = [vp(:);vp(end)];
        vs = [vs(:);vs(end)];
        rho= [rho(:);rho(end)];
    else
        m_data = load('model_data.dat');

        % Se obtiene el largo del archivo
        l_data = length(m_data);

        % Se crea el vector de espesor thk
        thk = m_data(:,1);
        thk = thk(1:l_data-1);

        % Se carga, vp, vs, rho
        vp = m_data(:,2);
        vs = m_data(:,3);
        rho = m_data(:,4);
    end
end
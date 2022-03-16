% Demo program for NRSfM_Consensus.

%
% NRSfM_Consensus is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.

clear; close all; clc;

%*************************************************************************************
% TODO: You have to load a ground truth 3D data (named "GT") here, e.g.;

datapath = './data_set/';
% datatype = 'benchmark/';
% dataname = 'walking'; %'walking';

datatype = 'symthetic_camera_rotations/';
dataname = 'yoga'; % drink, pickup, stretch, yoga
filename = '_rearranged.mat';
data = [datapath,datatype,dataname, filename];

% data = [datapath,dataname, filename];
load(data)

% GT should be (3 x p x f) dimensional, of the form;
%  La matriz de entrada es 3 X puntos X imágenes.
%  Para ejecutarlo solo necesitas la W, las anotaciones en la imagen, 
% es decir, GT(1:2,:,:).
GT = X;
% GT(1:2,:,:) = [ x_k1 x_k2 x_kp; y_k1 y_k2 y_kp; z_k1 z_k2 z_kp];
% GT(:, :, k) = [ x_k1 x_k2 x_kp; y_k1 y_k2 y_kp; z_k1 z_k2 z_kp];

% Here, x_ki, y_ki, and z_ki are the 3D coordinates of the ith point of the kth frame.
%*************************************************************************************
%% add rotation
ang = 5;
GT_rot = addRotation(ang,GT); 
% intentar de crear que pueda add y remove rotation entre un rg de frames
% que quiera el usuario...
% creo q deberia funcionar con el inverse matrix, pero no ! mirar porque!
plot_2D(GT_rot,dataname)
%%
% plot_2D(GT,dataname)
% Input data generation
D = GT(1:2, :, :);

% Diary save for command window
resulpath = './Results_error/';
final_name_data = sprintf("%s%s",resulpath,'RESULTS_',dataname,'.txt');
% diary(final_name_data)
d = datetime(now,'ConvertFrom','datenum');
disp(['**********************'+string(datetime)+'**********************'])
disp(['----------------------'+string(dataname)+'----------------------'])

% Consensus of Non-Rigid Reconstructions
X = NRSfM_Consensus(D);

%%
load Reconst_matlab_files\X_yoga.mat

%% Evaluation
GT = bsxfun(@minus, GT, mean(GT, 2));
vind = sum((GT(3, :, :)-X(3, :, :)).^2) > sum((GT(3, :, :)+X(3, :, :)).^2);
X(3, :, vind) = -X(3, :, vind);

perf = sqrt(reshape(sum(sum((GT-X).^2)), 1, [])./reshape(sum(sum(GT.^2)), 1, []));
disp("--------------------------MEAN ERROR---------------------------")
disp(['mean error : ' num2str(mean(perf))]); % string(dataname)+':'+

% diary off

%% Plot 3D results

for i=1:numel(perf)
    scatter3(GT(1, :, i), GT(3, :, i), GT(2, :, i), 'ro');
    hold on; scatter3(X(1, :, i), X(3, :, i), X(2, :, i), 'b.'); hold off;
    axis equal; title(dataname); drawnow;
end

% for i=1:numel(perf)
%     clf;
%     scatter3(GT(1, :, i), GT(3, :, i), GT(2, :, i), 'ro');
%     hold on; scatter3(X(1, :, i), X(3, :, i), X(2, :, i), 'b.'); hold off;
%     axis equal;
%     hold on;
%     title(dataname);
%     getframe;
%     pause;
% end

%% Save the reconstruct X
% X_path = ['./Reconst_matlab_files/X_'+string(dataname)+'.mat'];
% save(X_path,"X")
% saveas(Figure 1,dataname)

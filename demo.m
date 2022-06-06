% Demo program for NRSfM_Consensus.

% GT should be (3 x p x f) dimensional, of the form;
% To run it, we only need the annotations, ie. GT(1:2,:,:).
% GT(1:2,:,:) = [ x_k1 x_k2 x_kp; y_k1 y_k2 y_kp; z_k1 z_k2 z_kp];
% GT(:, :, k) = [ x_k1 x_k2 x_kp; y_k1 y_k2 y_kp; z_k1 z_k2 z_kp];
% Here, x_ki, y_ki, and z_ki are the 3D coord. of the ith point of the kth frame.

% W is the weight mask that indicates whether the
% elements are missing or not. (false = missing)

%% Dense Data Set
% seq = {'nikos', 'back', 'heart'}; % mostly imposible to run in my computer...
% ss  = 2;
% dataname = seq{ss};
% load(['./Data/dense/' seq{ss} '_rearranged.mat']);
% 
% if size(GT,1)==2
%     D=GT;
%     D(3,1)=0;
% end


%% Automatizar el testing

% clear; close all; clc;
rot_list = {'90'}; % '60','90','120' "BETTER ONE BY ONE"<----
% dataname = {'pickup', 'stretch', 'yoga'};  %drink   ESTE COMO TARDA MUCHO, LO PONDRE A PARTE!!
dataname = {'drink'};  %drink   ESTE COMO TARDA MUCHO, LO PONDRE A PARTE!!

datatype = {'noRotation', 'benchmark'};
% dataname = {'dinosaur_real','face_mocap','face_real','face','FRGC'}; %ogre_synthetic

%-------------------- CHANGE PARAMETRES------------------------
rot_flag = 1; %<--
datatype_idx= 2;
if rot_flag==0;datatype_idx= 1;rot_list={''};dataname = {'walking','dance','jaws','face'};end 

regu_type = {'SOFT','HARD'}; idx_regu = 2;%<--
regu_order = [1,2,4]; idx_L = 3; %<--


for odr= 2: size(regu_order,2)
    X_cell = cell(size(rot_list,2) ,size(dataname,2) );
    err_cell = cell(size(rot_list,2) ,size(dataname,2) );

    for i=1:size(rot_list,2) 
    
        for j= 1 : size(dataname,2)
            
            % Load the data
            path_data = ['./Data/' dataname{j} '_rearranged.mat'];
            if rot_flag==1
                path_data = ['./Data/rot_' rot_list{i} '/' dataname{j} '_' rot_list{i} '_rearranged.mat'];
            end
            load(path_data, 'X');
            
            [X_cell{i,j}, err_cell{i,j}] = get_principal_function(X,dataname{j}, ...
                                        rot_list{i},regu_order(idx_L),regu_type{idx_regu});
            
            
    
            % save for each dataset rotation individually
            path_save = sprintf('./Results_error/%s/L%d/data_%s_L%d_%s_rot_%s', ...
                                    regu_type{idx_regu}, regu_order(odr), ...
                                    regu_type{idx_regu}, regu_order(odr), ...
                                     datatype{datatype_idx}, rot_list{i}  );
            if dataname{1} == "drink"
                path_save = sprintf('./Results_error/%s/L%d/data_%s_L%d_%s_rot_%s', ...
                                    regu_type{idx_regu}, regu_order(odr), ...
                                    regu_type{idx_regu}, regu_order(odr), ...
                                     dataname{1}, rot_list{i}  );
            end
            save(path_save,'X_cell','err_cell')
        end
        
    
    end
end

% path_save = sprintf('./Results_error/datasets_rot_%s_withReguHardOrder_%d', rot_list{1}, regu_order(1));
% path_save = sprintf('./Results_error/datasets_rot_%s_withReguSoftOrder_%d', rot_list{1}, regu_order(1));
% save(path_save,'X_cell','err_cell')

%% Plot 3D results

% for i=1:numel(perf)
%     scatter3(GT(1, :, i), GT(3, :, i), GT(2, :, i), 'ro');% LO TIENE REVES, Y PINTA Y -> AXIZ Z
%     hold on; scatter3(X(1, :, i), X(3, :, i), X(2, :, i), 'b.'); hold off;
%     axis equal; title(dataname); drawnow;
% end

% 
% v_obj = VideoWriter(['./results/videos/' dataname '_video.avi']);
% % plot_NRSfM(D, W, GT, X, plot_NRSfM(D, W, GT, X););
% 
% list = [];
% plot_NRSfM(D, W, list, GT, X, v_obj);



%% Save VARIABLES, the reconstruct X
% X_path = ['./Reconst_matlab_files/X_'+string(dataname)+'.mat'];
% save(X_path,"X")
% saveas(Figure 1,dataname)

% clusters_3d_plots(Xi)

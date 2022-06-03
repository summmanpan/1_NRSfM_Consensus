function [X, err] = get_principal_function(GT,dataname,rot)
% GT data with gt of 3d structure
% dataname sting of filename 
% rot int as rot number

% noise, miss data generation.
% generate the diary and calculate the error

%% Input data generation

% Experimental setting
noise = 0; %10^-3;            % noise level. paper use 10^-3
rmiss = 0; %.001;            % missing rate, value lower than 1

[k, p, nSample] = size(GT);
D = zeros(k, p, nSample);
temp = GT(1:2, :, :);
% add normal random number
weight_noise = noise*max(abs(reshape(bsxfun(@minus, temp, mean(temp, 2)), [], 1)));
D(1:2, :, :) = temp + weight_noise*randn(2, p, nSample);


% Diary save for command window
resulpath = './Results_error/with_paper_rot/';
final_name_data = [resulpath 'ERROR_' dataname '_' rot '.txt'];
diary(final_name_data)
% d = datetime(now,'ConvertFrom','datenum'); % remove
disp(['***'+string(datetime)+'***'])
disp(['---'+string(dataname)+'---'])

% Consensus of Non-Rigid Reconstructions
X = NRSfM_Consensus(D);

%
% load Reconst_matlab_files\X_yoga.mat

%% Evaluation Error

GT = bsxfun(@minus, GT, mean(GT, 2));
vind = sum((GT(3, :, :)-X(3, :, :)).^2) > sum((GT(3, :, :)+X(3, :, :)).^2);
% > q hay mas diff GT que X, es decir si GT es 10, y X 7, pues la diff si
% es mas mas grande que la suma de 10 mas 7 , quiero decir que
% si es 10-10=0 > 20-> no errror
% si error es mayor que 0, o no error, lo invertimos.
% si es 3 > ?? 1-10=-9 > 10 -> falso-> es neg -> invertimos
% aseguramos de que la diff de GT - X, es positivo 

X(3, :, vind) = -X(3, :, vind);

perf = sqrt(reshape(sum(sum((GT-X).^2)), 1, [])./reshape(sum(sum(GT.^2)), 1, []));
disp(['---------------' dataname '-' rot '-MEAN ERROR---------------------------'])

if rmiss>0 && noise==0
    disp(['***WITH:***''Missing rate: '+string(rmiss)+'***'])
%     disp(['mean error : ' num2str(mean(perf))]); 
elseif  noise > 0 && rmiss==0
    disp(['***WITH:***''Noise rate: '+string(noise)+'***'])
%     disp(['mean error : ' num2str(mean(perf))]); 
elseif noise > 0 && rmiss>0
    disp(['***WITH:***''Noise rate: '+string(noise)+' AND ''Missing rate: '+string(rmiss)+'***'])
end
%     disp(['mean error : ' num2str(mean(perf))]); 
% else
%     disp(['mean error : ' num2str(mean(perf))]);
% end
err = num2str(mean(perf)); 
disp(['mean error : ' err]);

diary off

end
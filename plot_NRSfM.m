function plot_NRSfM( list, gX, rX, vidObj, flag_imgplot)
% function plot_NRSfM(D,  gX, rX, vidObj)
%
% Plot reconstructed results
%
% Inputs:
%     D: Observations                                 (3 x p x n)
%     
%     gX: Ground truth shapes                         (3 x p x n)
%     list: lines btw each points (lines, 2)
%     rX: Reconstructed shapes                        (3 x p x n)
%     vidObj: VideoWriter object (write a video file if specified)
%     flag_imgplot: if diff with 0, we plot that frame ---integer
% Ref: Minsik Lee, Jungchan Cho, Chong-Ho Choi, and Songhwai Oh,
% "Procrustean Normal Distribution for Non-Rigid Structure from Motion,"
% CVPR 2013, Portland, Oregon, June 23-28, 2013.
%
% Author: Minsik Lee (mlee.paper@gmail.com)
% Last update: 2013-09-07
% License: GPLv3

%
% Copyright (C) 2013 Minsik Lee, Jungchan Cho
% This file is part of NRSfM_PND.
%
% NRSfM_PND is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% NRSfM_PND is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with NRSfM_PND.  If not, see <http://www.gnu.org/licenses/>.
D = gX(1:2,:,:);

% init for vidObj
if  nargin < 5 || isempty(vidObj) %(nargin == 5 && ~ me lie en como gestionar para que list sea tamb variable vacio sin pasar desde el princiìo
    f_rate = 30;
    v_flag = false;
    % q entre cuando OBj es vacio
else
    open(vidObj) 
    f_rate = vidObj.FrameRate;
    v_flag = true;
end

nSample = size(D, 3);
nP = size(D, 2);

% D = bsxfun(@minus, D, sum(D, 2)./sum(W, 2)).*W;
D(isnan(D)) = 0; % quizas la linea de arriba borrar, y dejarlo con D(3,:)=0 ya de fuera
gX = bsxfun(@minus, gX, mean(gX, 2)); % estas medias son muy pequeñas
rX = bsxfun(@minus, rX, mean(rX, 2));
ind = sum((gX(3, :, :)-rX(3, :, :)).^2) > sum((gX(3, :, :)+rX(3, :, :)).^2);
rX(3, :, ind) = -rX(3, :, ind);

% axis
axD = [min(D(1, :)) max(D(1, :)) min(D(2, :)) max(D(2, :))];
axX = [min([gX(1, :) rX(1, :)]) max([gX(1, :) rX(1, :)]) min([gX(3, :) rX(3, :)]) max([gX(3, :) rX(3, :)]) min([gX(2, :) rX(2, :)]) max([gX(2, :) rX(2, :)])];

h = clf('reset');
set(h, 'Color', 'w');
% set(gcf, 'Position', [100,100,950,580]); seqq human
set(gcf, 'Position', [100,100,700,400]); % back

% put the access variables separalately to accelerate the coordinate access
if ~isempty(list)

    gXX = reshape(gX,3*nP,[]);
    x = gXX(1:3:end,:)';
    z = gXX(2:3:end,:)';
    y = gXX(3:3:end,:)';

    % GT points
    xp = [x(:,list(:,1)),x(:,list(:,2))];
    yp = [y(:,list(:,1)),y(:,list(:,2))];
    zp = [z(:,list(:,1)),z(:,list(:,2))];
    % estimate points
%     xp_e = [x_e(:,list(:,1)),x_e(:,list(:,2))];
%     yp_e = [y_e(:,list(:,1)),y_e(:,list(:,2))];
%     zp_e = [z_e(:,list(:,1)),z_e(:,list(:,2))];
end

back_plot = 0; % harkodeado
% if actriz, change the z,y to negative
if back_plot == 1
    %% back plot
    k =flag_imgplot;
    set(h, 'Name', [num2str(k) ' / ' num2str(nSample)]);

    subplot('Position',[1/3 0 1/3 0.9]);
%     scatter3(gX(1, :, k), gX(3, :, k), gX(2, :, k),'MarkerEdgeColor','k',...
%     'MarkerFaceColor',[0 .75 .75]); 
    scatter3(rX(1, :, k), rX(3, :, k), rX(2, :, k),'filled'); 
    axis('equal', axX, 'off'); grid off; 
    view(-45, 30); 

    drawnow limitrate;
    return
else
    for k=1:nSample
        TT = tic;
        set(h, 'Name', [num2str(k) ' / ' num2str(nSample)]);
        % 2D observation
        subplot('Position',[0 0 1/3 0.9]);
        scatter(D(1, :, k), D(2, :, k), 'k.');
        axis('equal', axD, 'off'); grid off;
        title('Input 2D tracks');
    
        % view 1
        subplot('Position',[1/3 0 1/3 0.9]);
        scatter3(rX(1, :, k), rX(3, :, k), rX(2, :, k),'MarkerEdgeColor','k',...
        'MarkerFaceColor',[0 .75 .75]); 
%         surf(rX(1, :, k), rX(3, :, k), rX(2, :, k))
        axis('equal', axX, 'off'); grid off; 
        view(45, 30); title('3D view 1');
        
        % view 2
        subplot('Position',[2/3 0 1/3 0.9]);
        scatter3(rX(1, :, k), rX(3, :, k), rX(2, :, k),'MarkerEdgeColor','k',...
        'MarkerFaceColor',[0 .75 .75]); 
        axis('equal', axX, 'off'); grid off;
        view(-45, 30); title('3D view 2');
        
        legend('Reconstructed', 'Location', 'SouthEast');
        drawnow limitrate;
    
        if v_flag
            writeVideo(vidObj, getframe(h));
        end
        
        pause(1/f_rate-toc(TT));
    end
    
    if v_flag
        close(vidObj);
    end
    return 
end


% flag_all =0; % false
if flag_imgplot ~= 0
    k = flag_imgplot;
    set(h, 'Name', [num2str(k) ' / ' num2str(nSample)]);
    % 2D observation
    subplot('Position',[0 0 1/3 0.9]);
    scatter(D(1, :, k), D(2, :, k), 'k.');
    axis('equal', axD, 'off'); grid off;
    title('Input 2D tracks');

    % view 1
    subplot('Position',[1/3 0 1/3 0.9]);
    scatter3(gX(1, :, k), gX(3, :, k), gX(2, :, k), 'ro'); 
    
    hold on;
%     scatter3(rX(1, :, k), rX(3, :, k), rX(2, :, k), 'b+'); 
%     if ~isempty(list); draw_lines(list,xp,yp,zp,k); end
%     hold off;

%     axis('equal', axX, 'off'); 
    axis('equal','off');
    grid off; 
    view(45, 30); title('3D view 1');
    
    % view 2
    subplot('Position',[2/3 0 1/3 0.9]);
    scatter3(gX(1, :, k), gX(3, :, k), gX(2, :, k), 'ro'); 
    
    hold on;
%     scatter3(rX(1, :, k), rX(3, :, k), rX(2, :, k), 'b+'); 
%     if ~isempty(list); draw_lines(list,xp,yp,zp,k);end
%     hold off;
    
%     axis('equal', axX, 'off'); 
    axis('equal','off');
    grid off;
    view(-45, 30); title('3D view 2');
    
%     legend('Ground truth','Reconstructed', 'Location', 'SouthEast');
    drawnow limitrate;

else 
    for k=1:nSample
        TT = tic;
        set(h, 'Name', [num2str(k) ' / ' num2str(nSample)]);
        % 2D observation
        subplot('Position',[0 0 1/3 0.9]);
    %     ind = all(W(1:2, :, k));
        scatter(D(1, :, k), D(2, :, k), 'k.');
        axis('equal', axD, 'off'); grid off;
        title('Input 2D tracks');
    
        % view 1
        subplot('Position',[1/3 0 1/3 0.9]);
        scatter3(gX(1, :, k), gX(3, :, k), gX(2, :, k), 'ro'); 
        hold on;
        scatter3(rX(1, :, k), rX(3, :, k), rX(2, :, k), 'b+'); 
        if ~isempty(list); draw_lines(list,xp,yp,zp,k); end
        hold off;
        axis('equal', axX, 'off'); grid off; 
        view(45, 30); title('3D view 1');
        
        % view 2
        subplot('Position',[2/3 0 1/3 0.9]);
        scatter3(gX(1, :, k), gX(3, :, k), gX(2, :, k), 'ro'); 
        hold on;
        scatter3(rX(1, :, k), rX(3, :, k), rX(2, :, k), 'b+'); 
        if ~isempty(list); draw_lines(list,xp,yp,zp,k);end
        hold off;
        axis('equal', axX, 'off'); grid off;
        view(-45, 30); title('3D view 2');
        
        legend('Ground truth','Reconstructed', 'Location', 'SouthEast');
        drawnow limitrate;
    
        if v_flag
            writeVideo(vidObj, getframe(h));
        end
        
        pause(1/f_rate-toc(TT));
    end
    if v_flag
        close(vidObj);
    end
end



end

function draw_lines(list,xp,yp,zp,k)

if exist('list','var')
        for j = 1:length(list) % we draw the lines, line by line, according with 2 points
%             hold on;
            plot3([xp(k,j) xp(k,length(list)+j)],[yp(k,j) yp(k,length(list)+j)],[zp(k,j) zp(k,length(list)+j)],'-',Color='black');
        end
%         hold off
end
% axis equal; drawnow limitrate;

end


%% back plot
%         k =flag_imgplot;
%         set(h, 'Name', [num2str(k) ' / ' num2str(nSample)]);
% 
%         subplot('Position',[1/3 0 1/3 0.9]);
%         scatter3(gX(1, :, k), gX(3, :, k), gX(2, :, k),'MarkerEdgeColor','k',...
%         'MarkerFaceColor',[0 .75 .75]); 
% 
%         axis('equal', axX, 'off'); grid off; 
%         view(-45, 30); 
% 
%         drawnow limitrate;
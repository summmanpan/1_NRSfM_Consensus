function X = reconstruct(D, rotK_th,max_ite,order_L,flag_soft,flag_regu)
% function X = reconstruct(D, rotK_th)
%
% Weak reconstructor
%
% Inputs:
%     D: Input 2D trajectory data                     (k x p x f)
%     rotK_th: Threshold for maximum K
%     max_ite = maximum iteration in case not convergence
%     order_L = order of the filter
%     flag_soft = to control the soft or hard constraint energy
%
% Outputs:
%     X: 3D reconstruction                            (k x p x f)


[k, p, f] = size(D);

% translate and normalize
[X, TX] = pout_trans(D);
sX = sqrt(sum(sum(X.^2)));
X = bsxfun(@rdivide, X, sX);

% calculate rotation
[R, ts] = cal_rotation(K_P_F2KF_P(X(1:2, :, :)), rotK_th);
sX = sX.*ts;
X = bsxfun(@rdivide, X, ts); % X(:, :, i) <- X(:, :, i)/ts(i) for all i
X = reshape(sum(bsxfun(@times, reshape(R, k, k, 1, f), reshape(X, k, 1, p, f))), k, p, f); % X(:, :, i) <- R(:, :, i)'*X(:, :, i) for all i
[X, R] = correct_reflection(X, R); % correct reflections

% calculate shapes
if flag_regu==2 % FLAG REGU IF 2 MEANS NO REGU
    X = BMM_old(X, reshape(R(3, :, :), 3, 1, []));
else
    X = BMM(X, reshape(R(3, :, :), 3, 1, []),max_ite, order_L, flag_soft);
end


% restore coordinates
X = reshape(sum(bsxfun(@times, reshape(R, k, k, 1, f), reshape(X, 1, k, p, f)), 2), k, p, f);
X = bsxfun(@times, X, sX);
X = bsxfun(@plus, X, TX);

end


function Y = K_P_F2KF_P(X)
% Convert (k x p x f) tensor to (kf x p) matrix

    Y = reshape(permute(X, [1 3 2]), [], size(X, 2));
end


function Y = BMM_old(X, R)
% Block matrix method
%
% X: 2D shapes (aligned in 3D)
% R: Third rows of rotation matrices
% Y: Reconstructed shapes
%
% This is a modified version of the block matrix method in
% Yuchao Dai, Hongdong Li, and Mingyi He,
% "A Simple Prior-free Method for Non-Rigid Structure-from-Motion Factorization,"
% CVPR 2012, Providence, Rhode Island, June 16-21, 2012.
% and
% Yuchao Dai, Hongdong Li, and Mingyi He,
% "A Simple Prior-free Method for Non-rigid Structure-from-Motion Factorization,"
% Int'l J. Computer Vision, vol. 107, no. 2, pp. 101-122, April 2014.

[k, p, nSample] = size(X);

mu = 1e-0;
rho = 1.02;

if k*p < nSample
    rest_svd = @(u, s, v) (bsxfun(@times, u, s')*v');
else
    rest_svd = @(u, s, v) (u*bsxfun(@times, s, v'));
end

count = 0;
cost = inf;
Z = zeros(1, p, nSample);
pXRZ = pout_sample(X);
L = zeros(size(X));
while cost > 1e-10

    Y = pXRZ - L;
    [U, S, V] = rsvd(reshape(Y, [], nSample));
    s = max(diag(S) - 1/mu, 0);
    Y = reshape(rest_svd(U, s, V), k, p, nSample);
    
    Z = Z - inner(R, pXRZ - Y - L);
    Z = pout_trans(Z);
    
    XRZ = X + outer(R, Z);
    pXRZ = pout_sample(XRZ);
    Q = Y - pXRZ;
    L = L + Q;
    cost = norm(Q(:))^2;

    mu = mu*rho;
    L = L/rho;

    count = count + 1;
%     if mod(count, 1e2) == 0
%         disp(['init ' num2str(count) ' : ' num2str(sum(s)) ' / ' num2str(cost) ' / ' num2str(mu)]);
%     end
end
% disp(['reconstruct ' num2str(count) ' : ' num2str(sum(s)) ' / ' num2str(cost) ' / ' num2str(mu)]);

Y = XRZ;

end


function Y = BMM(X, R, max_ite,order_L,flag_soft)
% Block matrix method
%
% X: 2D shapes (aligned in 3D)
% R: Third rows of rotation matrices
% Y: Reconstructed shapes
%
% This is a modified version of the block matrix method in
% Yuchao Dai, Hongdong Li, and Mingyi He,
% "A Simple Prior-free Method for Non-Rigid Structure-from-Motion Factorization,"
% CVPR 2012, Providence, Rhode Island, June 16-21, 2012.
% and
% Yuchao Dai, Hongdong Li, and Mingyi He,
% "A Simple Prior-free Method for Non-rigid Structure-from-Motion Factorization,"
% Int'l J. Computer Vision, vol. 107, no. 2, pp. 101-122, April 2014.

[k, p, nSample] = size(X);

mu = 1e-0;
rho = 1.02;

if k*p < nSample
    rest_svd = @(u, s, v) (bsxfun(@times, u, s')*v');
else
    rest_svd = @(u, s, v) (u*bsxfun(@times, s, v'));
end

count = 0;
cost = inf; 
Z = zeros(1, p, nSample);
pXRZ = pout_sample(X);

% Get L temporal smoothness priors matrix
L_t = get_L(nSample,order_L); % last parm order of L
L = zeros(size(X));
L2=0;
if flag_soft==false % if hard
    L2 = zeros(k*p, size(L_t,2));% HARD CONSTRAINT L2
end

L_tt = L_t*L_t' ; % MULTIPLICATION L AND L^T 
I1 = eye(nSample);
regu_T = (L_tt + I1);

while cost > 1e-10 && count < max_ite 


    Y = pXRZ - L;

    if flag_soft==true
        [U, S, V] = rsvd( reshape(Y, [], nSample) / regu_T );
    else
        [U, S, V] = rsvd( ( reshape(Y, [], nSample) - (L2 * (L_t)') ) / regu_T );
    end
    
    s = max(diag(S) - 1/mu, 0);
    Y = reshape(rest_svd(U, s, V), k, p, nSample); % nuclear norm
    
    Z = Z - inner(R, pXRZ - Y - L);
    Z = pout_trans(Z); % eliminate translation component
    
    XRZ = X + outer(R, Z);
    pXRZ = pout_sample(XRZ);
    Q = Y - pXRZ;
    
    %%% Covergence check / calculating the cost value %%%
    % Update Lagrange Multipliers 
    L = L + Q;
    cost = norm(Q(:))^2 ;

    if flag_soft==false
        Q2 = ( (reshape(Y, [], nSample)) *L_t); 
        L2 = L2 + Q2; % 3pxF
        cost = cost + norm(Q2(:))^2;
    end  
    
    % Update penalty weights
    mu = mu*rho;
    L = L/rho;


    count = count + 1;
%     if mod(count, 1e2) == 0
%         disp(['init ' num2str(count) ' : ' num2str(sum(s)) ' / ' num2str(cost) ' / ' num2str(mu)]);
%     end
end
% disp(['reconstruct ' num2str(count) ' : ' num2str(sum(s)) ' / ' num2str(cost) ' / ' num2str(mu)]);

Y = XRZ;

end

function L = get_L(frames, order)
% return a F ?? F matrix encoding temporal smoothness priors.

    switch(order)
        case 1
            % FIRST-ORDER
            % only 2 frames are consider to impulse the temporal constraint, 
            % 2 entries per columns
            L = -eye(frames,frames-1); % n_frames x n_frames-1 %eliminate last colum
            L(2:frames+1:end)=1;

        case 2
            %SECOND-ORDER
            L = eye(frames)*2;
            L(2:frames+1:end)=-1;
            L(frames+1:frames+1:end)=-1;
            % add boundary conditions to the 1st and last entries
            L(1,1)=1;
            L(frames,frames)=1;

        case 4
            % FOURTH-ORDER
            L = eye(frames)*-30;
            variable = 0;
            for i= 1:2
                if i~=1
                    variable = -16;
                end
                L(i+1:frames+1:end)= 16/(2-i+variable); 
                L((frames*i)+1:frames+1:end)= 16/(2-i+variable);
                % boundary conditions
                L(i,i)=variable;
                L(frames-(i-1),frames-(i-1))=variable;
                L(i,3-i)=1;
                L(frames-(i-1),frames-(2-i))=1; 
            end
            L(1,frames)=0; 
        otherwise
            disp('no exist filter order')
            L=0;
    end
end



function R = outer(X, Y)
% Outer product

    R = bsxfun(@times, X, Y);
end

function R = inner(X, Y)
% Inner product

    R = sum(bsxfun(@times, X, Y));
end


function [U, S, V] = rsvd(X)
% SVD based on EVD (sometimes built-in SVD function fails)

if diff(size(X)) > 0
    [U, D] = eig(X*X');
    [s, ind] = sort(sqrt(max(diag(D), 0)), 'descend');
    U = U(:, ind);
    S = diag(s);
    [V, H] = qr(X'*U, 0);
    ind = diag(H) < 0;
    V(:, ind) = -V(:, ind);
else
    [V, D] = eig(X'*X);
    [s, ind] = sort(sqrt(max(diag(D), 0)), 'descend');
    V = V(:, ind);
    S = diag(s);
    [U, H] = qr(X*V, 0);
    ind = diag(H) < 0;
    U(:, ind) = -U(:, ind);
end

end


function X = pout_sample(X)
% Eliminate mean component

    X = bsxfun(@minus, X, mean(X, 3));

end


function [X, R] = correct_reflection(X, R)
% Correct reflections signs between different frames
%
% X: 2D shapes (aligned in 3D)
% R: Rotation matrices

nSample = size(X, 3);

mX = X(:, :, 1);
pr = true(1, nSample);
r = false(1, nSample);
while any(xor(r, pr))
    pr = r;
    
    ind = sum(sum(bsxfun(@times, X, mX))) < 0;
    X(:, :, ind) = -X(:, :, ind);
    r(ind) = ~r(ind);
    
    mX = mean(X, 3);
end
R(1:2, :, r) = -R(1:2, :, r);

for i=1:nSample
    if det(R(:, :, i)) < 0
        r(i) = true;
    else
        r(i) = false;
    end
end
R(3, :, r) = -R(3, :, r);

end


function [R, s] = cal_rotation(X, th)
% Non-rigid factorization (rotation calculation)
%
% X: (kf x p) data matrix
% th: Threshold for maximum K
% R: Rotations
% s: Scales
%
% This is a modified version of the rotation calculation scheme in
% P. F. U. Gotardo and A. M. Martinez,
% "Non-Rigid Structure from Motion with Complementary Rank-3 Spaces,"
% CVPR 2011, Colorado Springs, Colorado, June 20-25, 2011.

[U, S, ~] = svd(X, 'econ');
ss = diag(S);
ss = cumsum(ss(1:end-1).^2);
maxK = sum(ss/ss(end) < th)+1;
maxK = min(ceil(maxK/3)*3, numel(ss));
F = U(:, 1:maxK);

lcost = inf;
for K = [3:3:size(F, 2)-1 size(F, 2)]
    plcost = lcost;

    [AA1, AA2, off] = cal_A_parts(F(:, 1:K));
    [A, LA] = pre([AA1-AA2; off]);
    if K == 3
        [GG, G] = cal_GG(A, eye(3)/3, 1e-12);
    else
        [GG, G] = cal_GG_m(A, [G zeros(size(G, 1), 3-size(G, 2)); zeros(K-size(G, 1), 3)], 3);
    end

    lcost = norm(A*GG(:))^2*LA;
    
%     disp([num2str(K) ' : ' num2str(plcost-lcost) ' / ' num2str(lcost)]);
    
    if lcost < eps
        break;
    end
end

[R, s] = F2R(F(:, 1:K)*[G zeros(size(G, 1), 3-size(G, 2))]);

end


function [R, s] = F2R(F)
% Project to rotation matrices

    s = zeros(1, 1, size(F, 1)/2);
    R = zeros(3, 3, numel(s));
    R(1:2, :, :) = permute(reshape(F, 2, [], 3), [1 3 2]);
    for i=1:numel(s)
        [U, S, V] = svd(R(:, :, i));
        R(:, :, i) = U*V';
        s(i) = trace(S)/2;
    end
    s = s/min(s);
end


function [A, LA] = pre(A)
% Precondition A matrix

    if diff(size(A)) < 0
        [~, A] = qr(A, 0);
    end
    LA = max(eig(A*A'));
    A = A/sqrt(LA);
end

function [GG, G, r] = cal_GG(A, GG, th)
% APG method for finding "rectification" matrix
%
% A: Basis matrix
% GG: outer product of G
% th: Threshold
% G: Rectification matrix
% r: Final rank of G

    if nargin < 3 || isempty(th)
        th = 1e-10;
    end
    cnt = 0;
    vcost = inf;
    AGG = A*GG(:);
    cost = norm(AGG)^2;
    tGG = GG;
    tAGG = AGG;
    t = 1;
    vGG = zeros(size(GG));
    while vcost/cost - 1 > th && vcost > eps
        pGG = GG;
        pAGG = AGG;
        pt = t;

        vGG(:) = tGG(:) - A'*tAGG;
        [GG, G, r] = prj_GG_u(vGG);

        AGG = A*GG(:);
        cost = norm(AGG)^2;
        
        vcost = norm(GG(:)-tGG(:))^2 + cost - norm(tAGG-AGG)^2;

        t = (1+sqrt(1+4*pt^2))/2;
        tGG = GG + (pt-1)/t*(GG-pGG);
        tAGG = AGG + (pt-1)/t*(AGG-pAGG);

        cnt = cnt+1;
%         if mod(cnt, 1e4) == 0
%             disp(['cal_GG ' num2str(cnt) ' : ' num2str(vcost - cost) ' / ' num2str(vcost) ' / ' num2str(cost) ' / ' num2str(norm(pGG(:)-GG(:))^2) ' / ' num2str(r) ' / ' num2str(length(GG))]);
%         end
    end
%     disp(['cal_GG ' num2str(cnt) ' : ' num2str(vcost - cost) ' / ' num2str(vcost) ' / ' num2str(cost) ' / ' num2str(norm(pGG(:)-GG(:))^2) ' / ' num2str(r) ' / ' num2str(length(GG))]);
end

function [GG, G, r] = cal_GG_m(A, G, m, th)
% PG method for finding "rectification" matrix (when K > 3)
%
% A: Basis matrix
% G: Rectification matrix
% GG: outer product of G
% m: Rank constraint
% th: Threshold
% r: Final rank of G

    if nargin < 4 || isempty(th)
        th = 1e-6;
    end
    G = fro_normalize(G(:, 1:m));
    GG = G*G';
    cnt = 0;
    pcost = inf;
    AGG = A*GG(:);
    cost = norm(AGG)^2;
    tID = tic;
    while pcost/cost - 1 > th
        pcost = cost;
        pGG = GG;

        GG(:) = GG(:) - A'*AGG;
        [GG, G, r] = prj_GG_u(GG, m);

        AGG = A*GG(:);
        cost = norm(AGG)^2;

        cnt = cnt+1;
%         if toc(tID) > 1
%             disp(['cal_GG_m ' num2str(cnt) ' : ' num2str(pcost/cost - 1) ' / ' num2str(cost) ' / ' num2str(norm(pGG(:)-GG(:))^2) ' / ' num2str(r) ' / ' num2str(m)]);
%             tID = tic;
%         end
    end
%     disp(['cal_GG_m ' num2str(cnt) ' : ' num2str(pcost/cost - 1) ' / ' num2str(cost) ' / ' num2str(norm(pGG(:)-GG(:))^2) ' / ' num2str(r) ' / ' num2str(m)]);
end


function G = fro_normalize(G)
% Normalize based on Frobenius norm

    G = G/norm(G(:));
end


function [AA1, AA2, off] = cal_A_parts(U)
% Calculate basis matrix for rotation calculation

K = size(U, 2);

A1 = U(1:2:end, :);
A2 = U(2:2:end, :);

AA1 = kron(A1, ones(1, K)).*repmat(A1, 1, K);
AA2 = kron(A2, ones(1, K)).*repmat(A2, 1, K);
off = repmat(reshape(A1, [], 1, K), 1, K).*repmat(A2, [1 1 K]);
off = reshape(off + permute(off, [1 3 2]), size(off, 1), []);

end


function [GG, G, r] = prj_GG_u(GG, m)
% Project to rank-m PSD matrix with unit trace
%
% GG: Input / output matrix
% m: Rank constraint
% G: Decomposed matrix
% r: Final rank of G

    [V, S] = eig(GG);
    if nargin < 2
        [s, ind] = prj_s_u(diag(S));
    else
        [s, ind] = prj_s_u(diag(S), m);
    end
    G = bsxfun(@times, V(:, ind), sqrt(s)');
    GG = G*G';
    r = sum(s > 0);
end


function [s, ind] = prj_s_u(s, m)
% Project to nonnegative vector with m nonzero elements and unit sum
%
% s: Input / output vector (output is sorted)
% m: Maximum number of nonzero elements
% ind: order of elements by sort

    [s, ind] = sort(s, 'descend');
    if nargin == 2
        s = s(1:m);
    end
    dcs = cumsum(s)-s.*(1:numel(s))';
    k = sum(dcs < 1);
    s = s(1:k) - s(k) + (1-dcs(k))/k;
    ind = ind(1:k);
end



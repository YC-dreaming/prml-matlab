%% Bayesian logistic regression for binary classification 
% (Page 353-356 of PRML)
% Optimization through Laplace approximation & IRLS.
% 
% X: N by P design matrix with N samples of M features
% t: N by 1 target values 
% w: P+1 by 1 weight vector
function [varargout] = bardlog1(t, X)

% add a constant column to cope with bias
PHI = cat(2, ones(size(X,1),1), X);
[N, P] = size(PHI);
t(find(t==-1)) = 0; % the class label should be [1 0]

% initialize with least square estimation
if (P > N)
    invC = woodburyinv(1e-4*eye(P),PHI',PHI,eye(N));
else
    invC = (1e-4*eye(P)+ PHI'*PHI)^(-1);
end
w = invC*PHI'*(t-mean(t));
% w = ones(P,1); % rough initialization
alphas= ones(P,1);

% stop conditions
d_w = Inf;
maxit = 100;
stopeps = 1e-6;
maxvalue = 1e9;

i = 1;
while (d_w > stopeps) && (i <= maxit)
    wold = w;
    
    index0 = find(alphas > min(alphas)*maxvalue);
    index1 = setdiff(1:P, index0);
    alphas1 = alphas(index1);
    PHI1 = PHI(:,index1);
    w1 = w(index1);
    
    %% E step (IRLS update)
    % get an optimal w (a number of GD updates) in each E step
    % [cost,grad] = funcCost(w1,PHI1,t,alphas1);
    % grad1 = numgrad(@(p)funcCost(p,PHI1,t,alphas1),w1);
    % disp([grad grad1]); 
    % diff = norm(grad1-grad)/norm(grad1+grad);
    % disp(diff); 
    options.maxIter = 200;
    options.display = 'off';
    [w1,cost] = minFunc(@(p)funcCost(p,PHI1,t,alphas1),w1,options);
    
    w(index1) = w1;
    if(~isempty(index0)) w(index0) = 0; end
    
    %% M step
    d = myeig(diag(sqrt(alphas))*PHI');
    d = diag(d);
    
    y = 1./(1+exp(-PHI*w)); % predicted target value
    diagR = y.*(1-y);
    R = diag(diagR);
    invR = diag(1./diagR);
    [N1,P1] = size(PHI1);
    if (P1>N1)
        Sigma1 = woodburyinv(diag(alphas1), PHI1', PHI1, invR);
    else
        Sigma1 = (diag(alphas1) + PHI1'*R*PHI1)^(-1);
    end
    gamma1 = 1 - alphas1.*diag(Sigma1);
    alphas1 = max(gamma1,eps)./(w1.^2+1e-32);
    alphas(index1) = alphas1;
    
    %% Calculate evidence
    t1 = PHI*w + invR*(t-y);
    if (P<N)
        invC = woodburyinv(R, PHI, PHI', diag(1./alphas));
    else
        invC = (R + PHI*diag(alphas)*PHI')^(-1);
    end
    evidence = (1/2)*(N*log(2*pi)+sum(log(d+diagR))+t1'*invC*t1);
    
    d_w = norm(w-wold)/(norm(wold)+1e-32);
    
    fprintf('Iteration %i: evidence = %f, wchange = %f\n', ...
        i, evidence, d_w);
    i = i + 1;
end

if(i < maxit)
    fprintf('Optimization of alpha and beta successfull.\n');
else
    fprintf('Optimization terminated due to max iteration.\n');
end

b = w(2:P);
b0 = w(1);

if nargout == 1
    model.b = b;
    model.b0 = b0;
    varargout{1} = model;
elseif nargout == 2
    varargout{1} = b;
    varargout{2} = b0;
end

end


function [cost,grad] = funcCost(w,PHI,t,alphas)

    y = 1./(1+exp(-PHI*w));
    grad = PHI'*(y-t) + diag(alphas)*w;
    cost = -sum(t.*log(y)+(1-t).*log(1-y)) + (1/2)*w'*diag(alphas)*w;
 
end

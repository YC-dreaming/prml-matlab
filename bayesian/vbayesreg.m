%% Variational linear regression with Gamma hyperprior
% (Page 486-490 of PRML)
% Soluted through variational approximation & EM.
% 
% X: N by P design matrix with N samples of M features
% t: N by 1 target values 
% w: P+1 by 1 weight vector
function [varargout] = vbayesreg(y,X)

% add a constant column to cope with bias
PHI = cat(2, ones(size(X,1),1), X);
[N, P] = size(PHI);

% initialize with least square estimation
if (P > N)
    invC = woodburyinv(1e-4*eye(P),PHI',PHI,eye(N));
else
    invC = (1e-4*eye(P)+ PHI'*PHI)^(-1);
end
w = invC*PHI'*y;
% w = ones(P,1); % rough initialization
an = 1;
bn = 1;
beta = 10;

% stop conditions
d_w = Inf;
maxit = 500;
stopeps = 1e-6;

i = 1;
while (d_w > stopeps)  && (i < maxit)
    wold = w;
    
    % E step
    alpha = an/bn;
    if (P > N)
        Sigma = woodburyinv(alpha*eye(P),PHI',PHI,(1/beta)*eye(N));
    else
        Sigma = (alpha*eye(P)+ beta*PHI'*PHI)^(-1);
    end
    w = beta*Sigma*PHI'*y;
    % M step
    an = an + 0.5*P;
    bn = bn + 0.5*(trace(Sigma)+w'*w);
    rmse = sum((y-PHI*w).^2);
    beta = N/(rmse+1e-32);
    
    % L = (P/2)*log(alpha) + (1/2)*log(det(Sigma));
    
    d_w = norm((w-wold)/wold);
    
    fprintf(['Iteration %i: wchange = %f, ' ...
        'rmse = %f, beta = %f, an = %f, bn = %f\n'], ...
        i, d_w, rmse, beta, an, bn);
    
    i = i + 1;
end

if(i < maxit)
    fprintf('Optimization successfull.\n');
else
    fprintf('Optimization terminated due to max iteration.\n');
end

b = w(2:end);
b0 = w(1);

if nargout == 1
    model.b = b;
    model.b0 = b0;
    varargout{1} = model;
elseif nargout == 2
    varargout{1} = b;
    varargout{2} = b0;
end

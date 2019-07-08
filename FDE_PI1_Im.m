function [t, y] = FDE_PI1_Im(alpha,f_fun,J_fun,t0,T,y0,h,param,tol,itmax)
% FDE_PI1_Im  Solves on the interval [t0,T] an initial value problem for a 
%             for a system D^alpha y = f(t,y) of differential equations of
%             fractional order alpha. Multi-order systems (MOS) are also
%             possible, i.e. systems in which each equation has a different
%             fractional order. 
%             The system or MOS of FDEs is solved by means of the implicit  
%             product-integration rule of rectangular type with convergence 
%             order equal to 1.  
%
% Further information on this code are available in [1]; please, cite this
% code as [1] (see later on). 
%
% -------------------------------------------------------------------------
% Description of input parameters
% -------------------------------------------------------------------------
% alpha     : vector of the fractional orders alpha of each equation of the
%             multi-order system of FDEs. 
% f_fun     : function handle that evaluates the right side f(t,y(t)) of
%             the MOS of FDEs. f_fun(t,y) must return a vector function  
%             with the same number of entries as alpha. If necessary,  
%             f_fun(t,y,param) can have a vector of parameters. 
% J_fun     : function handle that evaluates the Jacobian of the right side
%             f(t,y(t)) of the MOS of FDEs. J_fun must return a matrix
%             function with the same number of rows and columns as alpha.
%             If necessary, J_fun(t,y,param) can have a vector of 
%             parameters.
% t0, T     : starting and final time of the interval of integration.
% y0        : vector (or matrix) of initial conditions with a number of 
%             rows equal to the size of the problem (hence to the number of
%             entries of alpha or to the number of rows of the output of
%             f_fun) and a number of columns equal to the smallest integer
%             greater than max(alpha)
% h         : step-size for integration. It must be real and positive
% param     : vector of possible parameters for the evaluation of the
%             right side f(t,y(t)) and of its Jacobian. This an optional 
%             parameter: it can be omitted or it is possible to use the an
%             empty vector [] if the function f_fun(t,y) and its Jacobian 
%             do not have parameters. 
% tol       : tolerance for the solution of the internal nonlinear system
%             of equations. This is an optional parameter and when not
%             specified the defalut value 1.0e-6 is assumed. 
% itmax     : number of mximum iterations for the solution of the internal
%             nonlinear system of equations. This is an optional parameter
%             and when not specified the defalut value 100 is assumed.
%
% -------------------------------------------------------------------------
% Description of output parameters
% -------------------------------------------------------------------------
% t          : vector of nodes on the interval [t0,T] in which the
%              numerical solution is evaluated
% y          : matrix with the values of the solution evaluated in t
%
% -------------------------------------------------------------------------
% Possible usages
% -------------------------------------------------------------------------
% [t, y] = FDE_PI1_Im(alpha,f_fun,J_fun,t0,T,y0,h)
% [t, y] = FDE_PI1_Im(alpha,f_fun,J_fun,t0,T,y0,h,param)
% [t, y] = FDE_PI1_Im(alpha,f_fun,J_fun,t0,T,y0,h,param,tol)
% [t, y] = FDE_PI1_Im(alpha,f_fun,J_fun,t0,T,y0,h,param,tol,itmax)
%
% -------------------------------------------------------------------------
% References and other information
% -------------------------------------------------------------------------
%
%  [1] Garrappa R.: Numerical Solution of Fractional Differential
%  Equations: a Survey and a Software Tutorial, Mathematics 2018, 6(2), 16
%  doi: https://doi.org/10.3390/math6020016
%  downloadable pdf: http://www.mdpi.com/2227-7390/6/2/16/pdf  
%
%  Revision: 1.1 - Date: November, 30 2017
%
%  Please, report any problem or comment to :
%          roberto dot garrappa at uniba dot it
%
%  Copyright (c) 2017
%
%  Author:
%   Roberto Garrappa (University of Bari, Italy)
%   roberto dot garrappa at uniba dot it
%   Homepage: http://www.dm.uniba.it/Members/garrappa
%
% -------------------------------------------------------------------------
 
% Check inputs
if nargin < 10
    itmax = 100 ;
    if nargin < 9
        tol = 1.0e-6 ;
        if nargin < 8
            param = [] ;
        end
    end
end
 
% Check order of the FDEs
alpha = alpha(:) ;
if any(alpha <= 0)
    i_alpha_neg = find(alpha<=0) ;
    error('MATLAB:NegativeOrder',...
        ['The order ALPHA of the FDE must be positive. The value ' ...
        'ALPHA(%d) = %f can not be accepted.'], i_alpha_neg(1), alpha(i_alpha_neg(1)));
end
 
% Check the step--size of the method
if h <= 0
    error('MATLAB:NegativeStepSize',...
        ['The step-size H for the method must be positive. The value ' ...
        'H = %e can not be accepted.'], h);
end
 
% Check compatibility size of the problem with number of fractional orders
alpha_length = length(alpha) ; 
problem_size = size(y0,1) ;
if alpha_length > 1
    if problem_size ~= alpha_length
        error('MATLAB:SizeNotCompatible', ...
            ['Size %d of the problem as obtained from initial conditions ' ...
            '(i.e. the number of rows of Y0) not compatible with the ' ...
            'number %d of fractional orders for multi-order systems. ' ...
            ], problem_size, alpha_length);
    end
else
    alpha = alpha*ones(problem_size,1) ; 
    alpha_length = problem_size ;
end
 
% Storage of initial conditions
ic.t0 = t0 ;
ic.y0 = y0 ;
ic.m_alpha = ceil(alpha) ;
for i = 1 : alpha_length
    for j = 0 : ic.m_alpha(i)-1
        ic.m_alpha_factorial(i,j+1) = factorial(j) ;
    end
end
 
% Storage of information on the problem
Probl.ic = ic ;
Probl.f_fun = f_fun ;
Probl.J_fun = J_fun ;
Probl.problem_size = problem_size ;
Probl.param = param ;
Probl.alpha = alpha ;
Probl.alpha_length = alpha_length ;
 
% Check number of initial conditions
if size(y0,2) < max(ic.m_alpha)
    error('MATLAB:NotEnoughInitialConditions', ...
        ['A not sufficient number of assigned initial conditions. ' ...
        'Order ALPHA = %f requires %d initial conditions. '], ...
        max(alpha),max(ic.m_alpha));
end
 
% Check compatibility size of the problem with size of the vector field
f_temp = f_vectorfield(t0,y0(:,1),Probl) ;
if Probl.problem_size ~= size(f_temp,1)
    error('MATLAB:SizeNotCompatible', ...
        ['Size %d of the problem as obtained from initial conditions ' ...
        '(i.e. the number of rows of Y0) not compatible with the ' ...
        'size %d of the output of the vector field f_fun. ' ...
        ], Probl.problem_size,size(f_temp,1));
end
 
% Number of points in which to evaluate weights and solution
r = 16 ;
N = ceil((T-t0)/h) ;
Nr = ceil((N+1)/r)*r ;
Qr = ceil(log2(Nr/r)) - 1 ;
NNr = 2^(Qr+1)*r ;
 
% Preallocation of some variables
y = zeros(Probl.problem_size,N+1) ;
fy = zeros(Probl.problem_size,N+1) ;
zn = zeros(Probl.problem_size,NNr+1) ;
 
% Evaluation of coefficients of the PI rule
nvett = 0 : NNr+1 ; 
bn = zeros(Probl.alpha_length,NNr+1) ; 
for i_alpha = 1 : Probl.alpha_length
    find_alpha = find(alpha(i_alpha)==alpha(1:i_alpha-1)) ;
    if ~isempty(find_alpha)
         bn(i_alpha,:) = bn(find_alpha(1),:) ;
        %a0(i_alpha,:) = a0(find_alpha(1),:) ;
    else
        nalpha = nvett.^alpha(i_alpha) ;
        %bn(i_alpha,:) = [ 1 , nalpha(2:end) - nalpha(1:end-1) ] ;
        bn(i_alpha,:) = nalpha(2:end) - nalpha(1:end-1) ;
        %a0(i_alpha,:) = [ 0 , nalpha1(1:end-2)-nalpha(2:end-1).*(nvett(2:end-1)-alpha(i_alpha)-1)] ;
    end
end
PI.bn = bn ; 
PI.halpha1 = h.^alpha./gamma(alpha+1) ;
PI.tol = tol ; PI.itmax = itmax ;
 
% Evaluation of FFT of coefficients of the PI rule
PI.r = r ; 
if Qr >= 0
    index_fft = zeros(2,Qr+1) ;
    for l = 1 : Qr+1 % log2(NNr/r)
        if l == 1
            index_fft(1,l) = 1 ; index_fft(2,l) = r*2 ;
        else
            index_fft(1,l) = index_fft(2,l-1)+1 ; index_fft(2,l) = index_fft(2,l-1)+2^l*r;
        end
    end
     
    bn_fft = zeros( Probl.alpha_length,index_fft(2,end)) ;
    for l = 1 : Qr+1 % log2(NNr/r)
        coef_end = 2^l*r ;
        for i_alpha = 1 : Probl.alpha_length
            find_alpha = find(alpha(i_alpha)==alpha(1:i_alpha-1)) ;
            if ~isempty(find_alpha)
                bn_fft(i_alpha,index_fft(1,l):index_fft(2,l)) = bn_fft(find_alpha(1),index_fft(1,l):index_fft(2,l)) ;
            else
                bn_fft(i_alpha,index_fft(1,l):index_fft(2,l)) = fft(PI.bn(i_alpha,1:coef_end),coef_end) ;
            end
        end
    end
    PI.bn_fft = bn_fft ; PI.index_fft = index_fft ;
end
 
% Initializing solution and process of computation
t = t0 + (0 : N)*h ;
y(:,1) = y0(:,1) ;
fy(:,1) = f_temp ;
[y, fy] = Triangolo(1, r-1, t, y, fy, zn, N, PI, Probl ) ;
 
% Main process of computation by means of the FFT algorithm
ff = zeros(1,2.^(Qr+2)) ; ff(1:2) = [0 2] ; card_ff = 2 ;
nx0 = 0 ; ny0 = 0 ;
for qr = 0 : Qr
    L = 2^qr ; 
    [y, fy] = DisegnaBlocchi(L, ff, r, Nr, nx0+L*r, ny0, t, y, fy, ...
                             zn, N, PI, Probl ) ;
    ff(1:2*card_ff) = [ff(1:card_ff) ff(1:card_ff)] ; 
    card_ff = 2*card_ff ; 
    ff(card_ff) = 4*L ; 
end
 
% Evaluation solution in T when T is not in the mesh
if T < t(N+1)
    c = (T - t(N))/h ;
    t(N+1) = T ;
    y(:,N+1) = (1-c)*y(:,N) + c*y(:,N+1) ;
end
 
t = t(1:N+1) ; y = y(:,1:N+1) ;
 
end
 
 
% =========================================================================
% =========================================================================
% r : dimension of the basic square or triangle
% L : factor of resizing of the squares
%%
function [y, fy] = DisegnaBlocchi(L, ff, r, Nr, nx0, ny0, t, y, fy, ...
                                  zn, N , PI, Probl)
 
nxi = nx0 ; nxf = nx0 + L*r - 1 ;
nyi = ny0 ; nyf = ny0 + L*r - 1 ;
is = 1 ;
s_nxi(is) = nxi ; s_nxf(is) = nxf ; s_nyi(is) = nyi ; s_nyf(is) = nyf ;
 
i_triangolo = 0 ; stop = 0 ;
while ~stop
     
    stop = nxi+r-1 == nx0+L*r-1 | (nxi+r-1>=Nr-1) ; % Ci si ferma quando il triangolo attuale finisce alla fine del quadrato
     
    zn = Quadrato(nxi, nxf, nyi, nyf, fy, zn, N, PI, Probl) ;
     
    [y, fy] = Triangolo(nxi, nxi+r-1, t, y, fy, zn, N, PI, Probl) ;
    i_triangolo = i_triangolo + 1 ;
     
    if ~stop
        if nxi+r-1 == nxf   % Il triangolo finisce dove finisce il quadrato -> si scende di livello
            i_Delta = ff(i_triangolo) ;
            Delta = i_Delta*r ;
            nxi = s_nxf(is)+1 ; nxf = s_nxf(is)  + Delta ;
            nyi = s_nxf(is) - Delta +1; nyf = s_nxf(is)  ;
            s_nxi(is) = nxi ; s_nxf(is) = nxf ; s_nyi(is) = nyi ; s_nyf(is) = nyf ;
        else % Il triangolo finisce prima del quadrato -> si fa un quadrato accanto
            nxi = nxi + r ; nxf = nxi + r - 1 ; nyi = nyf + 1 ; nyf = nyf + r  ;
            is = is + 1 ;
            s_nxi(is) = nxi ; s_nxf(is) = nxf ; s_nyi(is) = nyi ; s_nyf(is) = nyf ;
        end
    end
     
end
 
end
 
 
% =========================================================================
% =========================================================================
function zn = Quadrato(nxi, nxf, nyi, nyf, fy, zn, N, PI, Probl)
 
coef_end = nxf-nyi+1 ;
i_fft = log2(coef_end/PI.r) ;
funz_beg = nyi+1 ; funz_end = nyf+1 ;
Nnxf = min(N,nxf) ; 
 
    if nyi == 0 % Evaluation of the lowest square
        vett_funz = [zeros(Probl.problem_size,1) , fy(:,funz_beg+1:funz_end) ] ;
    else
        vett_funz = fy(:,funz_beg:funz_end) ;
    end
    vett_funz_fft = fft(vett_funz,coef_end,2) ;
    zzn = zeros(Probl.problem_size,coef_end) ;
    for i = 1 : Probl.problem_size
        i_alpha = min(Probl.alpha_length,i) ;
        Z = PI.bn_fft(i_alpha,PI.index_fft(1,i_fft):PI.index_fft(2,i_fft)).*vett_funz_fft(i,:) ;
        zzn(i,:) = real(ifft(Z,coef_end)) ;
    end
    zzn = zzn(:,nxf-nyf+1:end) ;
    zn(:,nxi+1:Nnxf+1) = zn(:,nxi+1:Nnxf+1) + zzn(:,1:Nnxf-nxi+1) ;
 
end
 
 
% =========================================================================
% =========================================================================
function [y, fy] = Triangolo(nxi, nxf, t, y, fy, zn, N, PI, Probl)
 
for n = nxi : min(N,nxf)
     
    St = StartingTerm(t(n+1),Probl.ic) ;
  
    Phi = zeros(Probl.problem_size,1) ;
    for j = nxi : n-1
        Phi = Phi + PI.bn(1:Probl.alpha_length,n-j+1).*fy(:,j+1) ;
    end
    Phi_n = St + PI.halpha1.*(zn(:,n+1) + Phi) ;
         
    yn0 = y(:,n) ; fn0 = f_vectorfield(t(n+1),yn0,Probl) ;
    Jfn0 = Jf_vectorfield(t(n+1),yn0,Probl) ;
    Gn0 = yn0 - PI.halpha1.*fn0 - Phi_n ;
    stop = 0 ; it = 0 ;
     
    while ~stop
         
        JGn0 = eye(Probl.problem_size,Probl.problem_size) - diag(PI.halpha1)*Jfn0 ;
        yn1 = yn0 - JGn0\Gn0 ;
        fn1 = f_vectorfield(t(n+1),yn1,Probl) ;
        Gn1 = yn1 - PI.halpha1.*fn1 - Phi_n ;
        it = it + 1 ;
         
        stop = norm(yn1-yn0,inf) < PI.tol | norm(Gn1,inf) <  PI.tol;
        if it > PI.itmax && ~stop
            warning('MATLAB:NonConvegence',...
                strcat('Internal iterations do not convergence to the ', ...
                ' tolerance %e in %d iterations. Try with a larger tolarence ',...
                ' or a bigger number of max iterations'),PI.tol,PI.itmax) ;
            stop = 1 ;
        end
         
        yn0 = yn1 ; Gn0 = Gn1 ;
        if ~stop
            Jfn0 = Jf_vectorfield(t(n+1),yn0,Probl) ; 
        end        
         
        y(:,n+1) = yn1 ;
        fy(:,n+1) = fn1 ;
    end
end
 
end
 
 
% =========================================================================
% =========================================================================
function f = f_vectorfield(t,y,Probl)
 
if isempty(Probl.param)
    f = feval(Probl.f_fun,t,y) ;
else
    f = feval(Probl.f_fun,t,y,Probl.param) ;
end
 
end
 
 
% =========================================================================
% =========================================================================
function f = Jf_vectorfield(t,y,Probl)
 
if isempty(Probl.param)
    f = feval(Probl.J_fun,t,y) ;
else
    f = feval(Probl.J_fun,t,y,Probl.param) ;
end
 
end
 
% =========================================================================
% =========================================================================
function ys = StartingTerm(t,ic)
 
ys = zeros(size(ic.y0,1),1) ;
for k = 1 : max(ic.m_alpha)
    if length(ic.m_alpha) == 1
        ys = ys + (t-ic.t0)^(k-1)/ic.m_alpha_factorial(k)*ic.y0(:,k) ;
    else
        i_alpha = find(k<=ic.m_alpha) ;
        ys(i_alpha,1) = ys(i_alpha,1) + (t-ic.t0)^(k-1)*ic.y0(i_alpha,k)./ic.m_alpha_factorial(i_alpha,k) ;
    end
end
 
end
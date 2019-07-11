function y = my_fitness(population)
% population between[0,1]
t0=0;
T=1;
h=0.01;
y0=[2;-1;1];
alpha=[population(1),population(2),population(3)];
param=[1,0.1,1];
f_fun=@(t,y,par)([y(3)+(y(2)-par(1))*y(1);1-par(2)*y(2)-y(1)^2;-y(1)-par(3)*y(3)]);
J_fun=@(t,y,par)([-par(1),y(1),1;...
    -2*y(1),-par(2),0;...
    -1,0,-par(3)]);
[~,y_p]=FDE_PI1_Im(alpha,f_fun,J_fun,t0,T,y0,h,param);
%exact solution 
alpha=[0.9,0.85,0.95];
param=[1,0.1,1];
f_fun=@(t,y,par)([y(3)+(y(2)-par(1))*y(1);1-par(2)*y(2)-y(1)^2;-y(1)-par(3)*y(3)]);
J_fun=@(t,y,par)([-par(1),y(1),1;...
    -2*y(1),-par(2),0;...
    -1,0,-par(3)]);
[~,y_exact]=FDE_PI1_Im(alpha,f_fun,J_fun,t0,T,y0,h,param);
y =norm(y_p-y_exact);
end 


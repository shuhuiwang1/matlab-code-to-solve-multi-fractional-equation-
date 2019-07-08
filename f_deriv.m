function Y = f_deriv( y0, f, h, H,alpha)
%the y0 is the initial value,
%y is the function, 
%h is the lenght of step
%H is the [0,H]interval,
%alpha is the fractional order 
m=floor(alpha);
n=H/h;
b=zeros(1,n);
a=zeros(1,n);
for k=1:n
    b(k)=k^alpha-(k-1)^alpha;
    a(k)=(k+1)^(alpha+1)-2*k^(alpha+1)+(k-1)^(alpha+1);
end
y=zeros(1,n);
y(1)=y0(1);
for j=1:n
    p1=0;
    for k=0:(m-1)
        p1=p1+(j*h)^k/factorial(k)*y0(k+1);
    end
    p2=0;
    if j==1
        p2=b(2)*f(0,y(1));
    elseif j==n
        for k=1:(j-1)
            p2=p2+b(j-k+1)*f(k*h,y(k+1));
        end     
    else
        for k=0:(j-1)
            p2=p2+b(j-k+1)*f(k*h,y(k+1));
        end
    end 
    p3=0;
    for k=1:(j-1)
        p3=p3+a(j-k+1)*f(k*h,y(k+1));
    end
    p=p1+h^alpha/gamma(alpha+1)*p2;
    y(j)=p1+h^alpha/gamma(alpha+2)*(f(j*h,p)+((j-1)^(alpha+1)-...
        (j-1-alpha)*j^alpha)*f(0,y(1))+p3);
end
Y=y(1:n);
end 

    



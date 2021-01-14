function [f_surf] = plotEllipse(ax,origin,sizes)
%PLOTELLIPSE Summary of this function goes here
%   TODO: make work

a=sizes(1);
b=sizes(2);
c=sizes(3);
u=100;
[u,v]=meshgrid(-pi/2:0.1:pi/2,linspace(-pi,pi,length(u))); 
x=a*cos(u).*cos(v);
y=b*cos(u).*sin(v);
z=c*sin(u);

x=x+origin(1);
y=y+origin(2);
z=z+origin(3);
f_surf=surf(ax,x,y,z);

end


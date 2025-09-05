clear
clc
load('CBmod.mat');load('CBobs.mat');load('XSBNmod.mat');load('XSBNobs.mat')

Tdif=[CBmod.Tdif XSBNmod.Tdif];
absPAR=[CBmod.absPAR XSBNmod.absPAR];
absNIR=[CBmod.absNIR XSBNmod.absNIR];
V25=[CBmod.V25 XSBNmod.V25];
Leafsize=[CBmod.leafsize XSBNmod.leafsize];
%g1=[CBmod.leafsize XSBNmod.leafsize];

TdifabsPAR=[CBobs.TdifabsPAR ; XSBNobs.TdifabsPAR];
TdifabsNIR=[CBobs.TdifabsNIR ; XSBNobs.TdifabsNIR];
TdifV25=[CBobs.TdifV25 ; XSBNobs.TdifV25];
TdifLeafsize=[CBobs.TdifLeafsize ; XSBNobs.TdifLeafsize];
absPARobs=[CBobs.absPAR ; XSBNobs.absPAR];
absNIRobs=[CBobs.absNIR ; XSBNobs.absNIR];
V25obs=[CBobs.V25 ; XSBNobs.V25];
Leafsizeobs=[CBobs.Leafsize ; XSBNobs.Leafsize];

%vcmax25
X=V25; Y=Tdif;
x1=CBobs.V25;
y1=CBobs.TdifV25;
x2=XSBNobs.V25;
y2=XSBNobs.TdifV25;
plot_density_point(X,Y,0,200);hold on;
ft = fittype( 'exp1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
[fitresult_mod, gof_mod] = fit( X', Y', ft, opts );
plot_mod=plot( fitresult_mod );
set(plot_mod,'LineWidth',1.5,'Color',[0.247 0.247 0.247])

[fitresult_modCB, ~] = fit( CBmod.V25', CBmod.Tdif', ft, opts );
plot_modCB=plot( fitresult_modCB );
set(plot_modCB,'LineWidth',0.5,'Color',[0 0 1],'LineStyle','--')

[fitresult_modXSBN, ~] = fit( XSBNmod.V25', XSBNmod.Tdif', ft, opts );
plot_modXSBN=plot( fitresult_modXSBN );
set(plot_modXSBN,'LineWidth',0.5,'Color',[1 0 0],'LineStyle','--')

[fitresult_obCB, gof_ob1] = fit( x1, y1, ft);
plot1=plot( fitresult_obCB,'b-', x1, y1,'bo');
set(plot1,'LineWidth',1.2);


[fitresult_obXSBN, gof_ob2] = fit( x2, y2, ft);
plot2=plot( fitresult_obXSBN,'r-', x2, y2,'ro');
set(plot2,'LineWidth',1.2)


[fitresult_ob, gof_ob3] = fit( [x1; x2], [y1;y2], ft);
plot3=plot( fitresult_ob,[x1; x2], [y1;y2]);%,

set(plot3,'Color',[0.87,0.87,0.15],'LineWidth',1.5)
legend off
%legend([plot_mod,plot3(2)],'Simulation data', 'Field-measure data');
ylabel({'T_{leaf} -T_{air} (¡æ)'});
xlabel({'Vcmax25 (¦Ìmolm^{-2}s^{-1})'});
text('VerticalAlignment','baseline','FontSize',12,...
    'String',['R^2=' num2str(gof_mod.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob1.rsquare), sprintf('\n'),'R^2=' num2str(gof_ob2.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob3.rsquare)],...
    'position', [x1(1) y1(1)]);

%Leafsize
X=Leafsize; Y=Tdif;
% x1=CBobs.Leafsize;
% y1=CBobs.TdifLeafsize;
% x2=XSBNobs.Leafsize;
% y2=XSBNobs.TdifLeafsize;
x1 = 0.01*[6.47	5.41	5.43	8.80	4.03	8.63	7.62	4.58	4.10	5.41	5.43	5.00	6.49	4.56	4.13	7.56	4.00	4.00]';
y1 = [2.0299	2.1398	2.2361	3.2270	0.7291	2.1451	5.6508	5.0256	1.4200	2.8394	2.0595	0.5972	2.4290	1.6289	3.9476	2.4455	0.1855	0.5352]';
x2 = 0.01*[4.85	10.2	4.86	10.00	8.57	6.00	10.20	6.40	5.50	5.00	6.75	13.00	6.00	10.20	8.57	4.85	4.43	4.8	 6.40	4.43	6.00	8.50]';
y2 = [3.2690	5.2006	4.4750	3.9699	5.2213	4.5432	5.4289	2.3094	4.2253	4.8343	4.6297	5.5297	3.2138	3.4627	4.0204	3.5780	2.7685	2.1471	2.8141	2.5292	4.8437	3.1178]';

plot_density_point(X,Y,0,200);hold on;
ft = fittype( 'poly1' );
opts = fitoptions( 'Method', 'LinearLeastSquares' );
[fitresult_mod, gof_mod] = fit( X', Y', ft, opts );
plot_mod=plot( fitresult_mod );
set(plot_mod,'LineWidth',2,'Color',[0.247 0.247 0.247])

[fitresult_obCB, gof_ob1] = fit( x1, y1, ft);
plot1=plot( fitresult_obCB,'b-', x1, y1,'bo');
set(plot1,'LineWidth',1.2)

[fitresult_obXSBN, gof_ob2] = fit( x2, y2, ft);
plot2=plot( fitresult_obXSBN,'r-', x2, y2,'ro');
set(plot2,'LineWidth',1.2)

[fitresult_ob, gof_ob3] = fit( [x1; x2], [y1;y2], ft);
plot3=plot( fitresult_ob,[x1; x2], [y1;y2]);%,             
set(plot3,'Color',[0.87,0.87,0.15],'LineWidth',1.5)
legend off
%legend([plot_mod,plot3(2)],'Simulation data', 'Field-measure data');
ylabel({'T_{leaf} -T_{air} (¡æ)'});
xlabel({'Leaf size (m)'});
text('VerticalAlignment','baseline','FontSize',12,...
    'String',['R^2=' num2str(gof_mod.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob1.rsquare), sprintf('\n'),'R^2=' num2str(gof_ob2.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob3.rsquare)],...
    'position', [x1(1) y1(1)]);

%absPAR
X=absPAR; Y=Tdif;
% x1=CBobs.absPAR;
% y1=CBobs.TdifabsPAR;
% x2=XSBNobs.absPAR;
% y2=XSBNobs.TdifabsPAR;
x1 = [0.9467	0.9307	0.8415	0.9390	0.9310	0.9465	0.9319	0.9448	0.9240	0.8733	0.9404	0.9192	0.9166	0.9403	0.9313	0.8608	0.9263	0.9081]';
y1 = [2.0299	2.1398	2.2361	3.2270	0.7291	2.1451	5.6508	5.0256	1.4200	2.8394	2.0595	0.5972	2.4290	1.6289	3.9476	2.4455	0.1855	0.5352]';
x2 = [0.9312	0.9354	0.8882	0.9516	0.9430	0.9111	0.9355	0.9375	0.9237	0.9200	0.9298	0.9236	0.9227	0.9428	0.9338	0.8890	0.9383	0.8599	0.9430	0.9227	0.9157	0.9519]';
y2 = [3.2690	5.2006	4.4750	3.9699	5.2213	4.5432	5.4289	2.3094	4.2253	4.8343	4.6297	5.5297	3.2138	3.4627	4.0204	3.5780	2.7685	2.1471	2.8141	2.5292	4.8437	3.1178]';
plot_density_point(X,Y,0,200);hold on;
ft = fittype( 'poly1' );
opts = fitoptions( 'Method', 'LinearLeastSquares' );
[fitresult_mod, gof_mod] = fit( X', Y', ft, opts );
plot_mod=plot( fitresult_mod );
set(plot_mod,'LineWidth',2,'Color',[0.247 0.247 0.247])

[fitresult_modCB, ~] = fit( CBmod.absPAR', CBmod.Tdif', ft, opts );
plot_modCB=plot( fitresult_modCB );
set(plot_modCB,'LineWidth',0.5,'Color',[0 0 1],'LineStyle','--')

[fitresult_modXSBN, ~] = fit( XSBNmod.absPAR', XSBNmod.Tdif', ft, opts );
plot_modXSBN=plot( fitresult_modXSBN );
set(plot_modXSBN,'LineWidth',0.5,'Color',[1 0 0],'LineStyle','--')

[fitresult_obCB, gof_ob1] = fit( x1, y1, ft);
plot1=plot( fitresult_obCB,'b-', x1, y1,'bo');
set(plot1,'LineWidth',1.2)

[fitresult_obXSBN, gof_ob2] = fit( x2, y2, ft);
plot2=plot( fitresult_obXSBN,'r-', x2, y2,'ro');
set(plot2,'LineWidth',1.2)

[fitresult_ob, gof_ob3] = fit( [x1; x2], [y1;y2], ft);
plot3=plot( fitresult_ob,[x1; x2], [y1;y2]);%,
set(plot3,'Color',[0.87,0.87,0.15],'LineWidth',1.5)
legend off
%legend([plot_mod,plot3(2)],'Simulation data', 'Field-measure data');
ylabel({'T_{leaf} -T_{air} (¡æ)'});
xlabel({'absorptivity of PAR'});
text('VerticalAlignment','baseline','FontSize',12,...
    'String',['R^2=' num2str(gof_mod.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob1.rsquare), sprintf('\n'),'R^2=' num2str(gof_ob2.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob3.rsquare)],...
    'position', [x1(1) y1(1)]);

%absNIR
X=absNIR; Y=Tdif;
% x1=CBobs.absNIR;
% y1=CBobs.TdifabsPAR;
% x2=XSBNobs.absNIR;
% y2=XSBNobs.TdifabsNIR;

x1 = [0.4989	0.4153	0.4132	0.4895	0.4767	0.4795	0.5150	0.4649	0.4869	0.3883	0.4109	0.4522	0.4270	0.4374	0.4966	0.5371	0.4682	0.4853]';
y1 = [2.0299	2.1398	2.2361	3.2270	0.7291	2.1451	5.6508	5.0256	1.4200	2.8394	2.0595	0.5972	2.4290	1.6289	3.9476	2.4455	0.1855	0.5352]';
x2 = [0.4499	0.4216	0.4291	0.5608	0.5344	0.3959	0.4836	0.4920	0.5293	0.4798	0.5324	0.4041	0.4119	0.5198	0.5594	0.4077	0.4261	0.4753	0.4886	0.3970	0.5315	0.5273]';
y2 = [3.2690	5.2006	4.4750	3.9699	5.2213	4.5432	5.4289	2.3094	4.2253	4.8343	4.6297	5.5297	3.2138	3.4627	4.0204	3.5780	2.7685	2.1471	2.8141	2.5292	4.8437	3.1178]';

plot_density_point(X,Y,0,200);hold on;
ft = fittype( 'poly1' );
opts = fitoptions( 'Method', 'LinearLeastSquares' );
[fitresult_mod, gof_mod] = fit( X', Y', ft, opts );
plot_mod=plot( fitresult_mod );
set(plot_mod,'LineWidth',2,'Color',[0.247 0.247 0.247])

[fitresult_modCB, gof_modCB] = fit( CBmod.absNIR', CBmod.Tdif', ft, opts );
plot_modCB=plot( fitresult_modCB );
set(plot_modCB,'LineWidth',0.5,'Color',[0 0 1],'LineStyle','--')

[fitresult_modXSBN, gof_modXSBN] = fit( XSBNmod.absNIR', XSBNmod.Tdif', ft, opts );
plot_modXSBN=plot( fitresult_modXSBN );
set(plot_modXSBN,'LineWidth',0.5,'Color',[1 0 0],'LineStyle','--')

[fitresult_obCB, gof_ob1] = fit( x1, y1, ft);
plot1=plot( fitresult_obCB,'b-', x1, y1,'bo');
set(plot1,'LineWidth',1.2)

[fitresult_obXSBN, gof_ob2] = fit( x2, y2, ft);
plot2=plot( fitresult_obXSBN,'r-', x2, y2,'ro');
set(plot2,'LineWidth',1.2)

[fitresult_ob, gof_ob3] = fit( [x1; x2], [y1;y2], ft);
plot3=plot( fitresult_ob,[x1; x2], [y1;y2]);%,
set(plot3,'Color',[0.87,0.87,0.15],'LineWidth',1.5)
legend off
%legend([plot_mod,plot3(2)],'Simulation data', 'Field-measure data');
ylabel({'T_{leaf} -T_{air} (¡æ)'});
xlabel({'absorptivity of NIR'});
text('VerticalAlignment','baseline','FontSize',12,...
    'String',['R^2=' num2str(gof_mod.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob1.rsquare), sprintf('\n'),'R^2=' num2str(gof_ob2.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob3.rsquare)],...
    'position', [x1(1) y1(1)]);

%g1
X=Leafsize; Y=Tdif;
x1=CBobs.Leafsize;
y1=CBobs.TdifLeafsize;
x2=XSBNobs.Leafsize;
y2=XSBNobs.TdifLeafsize;
plot_density_point(X,Y,0,200);hold on;
ft = fittype( 'poly1' );
opts = fitoptions( 'Method', 'LinearLeastSquares' );
[fitresult_mod, gof_mod] = fit( X', Y', ft, opts );
plot_mod=plot( fitresult_mod );
set(plot_mod,'LineWidth',2,'Color',[0.247 0.247 0.247])

[fitresult_obCB, gof_ob1] = fit( x1, y1, ft);
plot1=plot( fitresult_obCB,'b-', x1, y1,'bo');
set(plot1,'LineWidth',1.2)

[fitresult_obXSBN, gof_ob2] = fit( x2, y2, ft);
plot2=plot( fitresult_obXSBN,'r-', x2, y2,'ro');
set(plot2,'LineWidth',1.2)

[fitresult_ob, gof_ob3] = fit( [x1; x2], [y1;y2], ft);
plot3=plot( fitresult_ob,[x1; x2], [y1;y2]);%,
set(plot3,'Color',[0.87,0.87,0.15],'LineWidth',1.5)
legend off
%legend([plot_mod,plot3(2)],'Simulation data', 'Field-measure data');
ylabel({'T_{leaf} -T_{air} (¡æ)'});
xlabel({'Leaf size (m)'});
text('VerticalAlignment','baseline','FontSize',12,...
    'String',['R^2=' num2str(gof_mod.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob1.rsquare), sprintf('\n'),'R^2=' num2str(gof_ob2.rsquare),sprintf('\n'),'R^2=' num2str(gof_ob3.rsquare)],...
    'position', [x1(1) y1(1)]);
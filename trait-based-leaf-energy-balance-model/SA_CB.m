clear
clc
%% enviromental parameters obtain from CB field measure during growth season
filename='Weather record_CBS.xlsx';
T = readtable(filename);
T_canopy=T(strcmp(T.Location,'Canopy'),:);
index_day=(day(datetime(T_canopy.Time))==8);
% index1=find(index_day==1);
% index_day(index1(end)+1:index1(end)+240)=1;
% index_day(index1(1)-60:index1(1)-1)=1;
time=T_canopy.Time;
time=time(index_day);
Tair_c=T_canopy.AirTemperature__C;
u_c=T_canopy.WindSpeed_km_h;
RH_c=T_canopy.AirRH__;
PAR_c=T_canopy.PAR_uM_m_2s;
Meteo_whole=[ Tair_c u_c PAR_c RH_c];
Meteo=Meteo_whole(index_day,:);
Meteo1=Meteo(30:30:length(Meteo(:,1)),:);
PAR_init=Meteo1(:,3);
PAR_init(PAR_init<30)=0;%PAR<30, no photosynthesis
ind_day=find(PAR_init>0);
PAR_init(ind_day(1):ind_day(end))=smooth(PAR_init(ind_day(1):ind_day(end)),4);
plot(PAR_init);
for i=1:length(Meteo1(1,:))
    Meteo1(:,i)= smooth(Meteo1(:,i),4);
end
Meteo1(:,3)=PAR_init;
%% leaf energy balance model calculation
pmin_t=[0.01, % leaf size
    0.73, % absorb_PAR
    0.24, % absorb_NIR
    0.95, % absorb_L
    13,   % V25
    0.81];% g1
pmax_t=[0.4, % leaf size
    0.96, % absorb_PAR
    0.62, % absorb_NIR
    0.995,% absorb_L
    160,  %  V25
    10.58];% g1

Np=length(pmax_t);
constant.cp=29.3; % J/mol/? specific heat capacity of air
constant.g=9.8; % m/s^2 gravitational constant
%numbers=[50 100 200 300 400 500 600 800 1000 1200 1400 1600 2000]';
%numbers=[3000 4000 5000 6000]';
%for i0=1:length(numbers)
Ns=400*ones(5,1);
T_leaf=zeros(Ns(1),length(Meteo1(:,1)),length(Ns));
Tleaf_temp1=zeros(Ns(1),1);
exitflag_temp1=zeros(Ns(1),1);

Sti=zeros(length(Meteo1(:,1)),Np);
Si=zeros(length(Meteo1(:,1)),Np);

for i=1:length(Meteo1(:,1))
    S_vec=zeros(length(Ns),Np);
    ST_vec=zeros(length(Ns),Np);
    tic
    for num=1:length(Ns)
        clear X1 X2 X p
        skip=randi(1000);leap=randi([1000 10000]);
        p = sobolset(Np+1,'Skip',skip,'Leap',leap);
        p = scramble(p,'MatousekAffineOwen');
        N=Ns(num);
        X0 = net(p,N);
        X1=X0(:,2:end);
        X1 = parameterdist(X1,pmax_t,pmin_t,0,1,'unif'); %%this is what assigns 'our' values rather than 0:1 dist
        X2 =[Meteo1(i,1)*ones(N,1) 1.16*ones(N,1) Meteo1(i,3)/4.57*ones(N,1) Meteo1(i,4)*ones(N,1) 101.3*ones(N,1)  0.1*ones(N,1)];
        X  =[X1 X2];
        Ci   = 280;
        out0 = trait_based_energy_balance_model(X,Ci,constant);
        Tleaf_temp1 = out0;
        A = X1(1:N/2,:);
        B = X1(N/2+1:N,:);
        
        YA=Tleaf_temp1(1:N/2,1);
        YB=Tleaf_temp1(N/2+1:N,1);
        Y = [YA; YB];
        % ABi matrices formed by all colums of A except the k column, which comes from B
        ABi = cell(1,Np);
        for k = 1:Np
            ABi{k} = A;
            ABi{k}(:,k) = B(:,k);
        end
        V_vec = var(Y); % Total variance (1xNd) of every column in every sample time
        YABi = cell(1,Np);
        for k = 1:Np
%             Tleaf_temp1=zeros(length(A(:,1)),1);
            Xj=[ABi{k} X2(1:length(A(:,1)),:)];
            out1 = Func_JorhNorman_leaf_temperature_efast(Xj,Ci,constant);
            Tleaf_temp1 = out1;
            YABi{k}=Tleaf_temp1;
            S_vec(num,k) = 1 - mean((YB - YABi{k}).^2)./(2*V_vec);%
            ST_vec(num,k) = mean( (YA - YABi{k}).^2)./(2*V_vec);%
        end
        [i num]
    end
    
    for num1=1:Np
        clear temp_Si temp_Sti
        temp_Si = abs(S_vec(:,num1));
        temp_Sti=abs(ST_vec(:,num1));
        remain_si=abs(temp_Si-mean(temp_Si))<=1*std(temp_Si);
        remain_sti=abs(temp_Sti-mean(temp_Sti))<=1*std(temp_Sti);
        Sti(i, num1)=mean(temp_Sti(remain_sti));
        Si(i, num1)=mean(temp_Si(remain_si));
    end
    save (['LeaftraitSACB_u=mean' num2str(N) '_' num2str(i)  '.mat']);
    toc
end
%     Std(i0,1)=mean(std(ST_vec));
%     Std(i0,2)=mean(std(S_vec));
%end

%%post-processes
Sti=[Sti(end,:); Sti(1:end-1,:)];%CB solar time
for i=1:length(Sti(1,:))
    Sti(12:end-9,i)= smooth(Sti(12:end-9,i),3);
end

figure;
x=(1:48)';
Stin=Sti;
%Stin=[y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11];
Stin1=Stin./sum(Stin,2);
%bar(Stin./sum(Stin,2),'stack')
color_parula=[69,117,180;145,191,219;198,216,247;254,224,144;252,141,89;215,48,39]/255;
%color_parula=[69,117,180;145,191,219;224,243,248;215,48,39;252,141,89;254,224,144]/255;
s = 0;
fill([x' fliplr( x')],[0*ones(48,1)' fliplr(Stin1(:,1)')],color_parula(1,:))
hold on
for i=2:6
    s=s+Stin1(:,i-1);
    fill([x' fliplr( x')],[s' +fliplr((s+Stin1(:,i))')], color_parula(i,:))
end

xlim([1 48]);ylim([0 1]);
xticks([4:4:48]);
xticklabels({'2','4','6','8','10','12','14','16','18','20','22','24'});
xlabel('Local solar time');ylabel('Relative contribution');

xticks([7:8:47]);
xticklabels({'4','8','12','16','20','24'});

clc;
close all;
clear all;

P_max = 1491000;      %Shaft power of PW120 (W)
motor_eff = 0.9;      %given motor eff
P_req = P_max/motor_eff;
P_FC = P_req;         %fuel cell power required given efficiency (W)

%%from (Doimin et al (2025)) in agreement with book ISBN: 9781420044317
FC_eff = 0.444;
P_react = P_FC/FC_eff;        %%chemical power reqd (W)

%%%from Wiley extract, ISBN: 0-470-84857-X, link: https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781118878330.app2
V_c = FC_eff*1.25;  %%cell voltage from wiley
lambda = 2;   %% stoichiometric constatn

O2_dot = (8.29E-08)*(P_FC/V_c);     %%kg/s

air_dot = (3.57E-07)*lambda*(P_FC/V_c);   %%kg/s

air_exit = air_dot - O2_dot;      %%kg/s

H2_dot = (1.05E-08)*(P_FC/V_c);     %%kg/s

H2o_dot = (9.34E-08)*(P_FC/V_c);     %%kg/s

Heat_prod = P_FC*((1.25/V_c) - 1);     %%W

fprintf("For a required shaft power of: %.4f kW \n\n", P_max/1000);
fprintf("With a motor efficiency of 90%% \n\n");
fprintf("Fuel cell stack power output is %.4f kW \n\n", P_FC/1000);
fprintf("With a fuel cell efficiency of 44.4%% \n\n");
fprintf("Average cell voltage is %.3f V \n\n" , V_c);
fprintf("O_2 flow rate is %.4f kg/s \n\n", O2_dot);
fprintf("Air inlet flow rate is %.4f kg/s \n\n", air_dot);
fprintf("Air outlet flow rate is %.4f kg/s \n\n", air_exit);
fprintf("H_2 flow rate is %.4f kg/s \n\n", H2_dot);
fprintf("Water vapour production rate is %.4f kg/s \n\n", H2o_dot);
fprintf("and the heat production rate is %.4f kW \n\n", Heat_prod/1000);

%%Liquid Cooled Model approach
cool_Cp = 2840;   %%spec. heat capac. of coolant from tables (ethelyn-glycol)
air_Cp = 1005;     %%spec. heat capac. of air from tables (ethelyn-glycol)
T_oper = 80;      %5 operational temp of cells and hence, hot inlet of coolant
T_ho = 70;        %%this is an ssumed value and can be changed
T_ci = 15;        %% ambient air temp
T_co = 40;        %%%this is assumed air temp outlet, can be changed

Cool_dot = Heat_prod/((cool_Cp)*(T_oper-T_ho));
HXair_dot = Heat_prod/((air_Cp)*(T_co - T_ci));

%%% eps-NTU approach

C_max = Cool_dot*cool_Cp;
C_min = HXair_dot*air_Cp;
C_r = C_min/C_max;
q_max = C_min*(T_oper-T_ci);
eps = Heat_prod/q_max;

eps_ntu = @(NTU) 1 - exp(((1/C_r)*(NTU)^0.22) * (exp(-C_r*(NTU)^0.78)-1)) - eps;
NTU = fzero(eps_ntu, [0.01,5]);
UA = NTU*C_min;
ref_U = 167;        %%U-value taken from (Mitkar (2025))
A = UA/ref_U;        %%(m^2)
Area_density = 651.67;    %%calculated from (Mitkar (2025));

Front_A = A/Area_density;
fprintf("Radiator frontal area is %.4f m^2\n\n", Front_A);








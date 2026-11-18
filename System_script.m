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






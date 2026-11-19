clc;
close all;
clear all;

P_ISA = 101.325     %%ambient ISA pressure
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

fprintf("****************Fuel Cell Parameters********************\n\n");
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
T_oper = 85;      %5 operational temp of cells and hence, hot inlet of coolant
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

volume = A/Area_density;
rad_depth = 0.2;      %%reasonable assumed depth of rad
Front_A = volume/rad_depth;
fprintf("***********Liquid Cooled System**************\n\n");
fprintf("Radiator frontal area is %.4f m^2\n\n", Front_A);


%%%% EC_HT system *********************************************************************************************

spec_lat_wat = 2.26E06;    %spec. latent heat of evaporation of water
inject_dot = Heat_prod/spec_lat_wat;

%%%condenser calculations. condeser takes the dry air and water valpour mix and cools it in exchanger such that water may be condesed for recirculation
cond_T = 80;      %%%(degree celcius) NOTE THIS IS ASSUMED TEMP. temperature of interest in EC-HT, recompression of cathode fluids prior to condensor increases T of fluids
cond_P = 260;      %%%(kPa) NOTE THIS IS ASSUMED PRESSURE.this is the pressure of interest in EC-HT, recompression of cathode fluids prior to condensor to increase P and hence T of fluids by PV =RT

%%fluids exiting the cell stack
vap_exit = H2o_dot + inject_dot
dry_air = air_exit;

%%caluclate partial pressure based off molar mass (daltons law)
molar_water = 18.015;     %%molar mass of water
molar_air = 28.97;        %%molar mass of air

partial_water = (vap_exit/molar_water)/((vap_exit/molar_water)+(dry_air/molar_air)); %%molar fraction of water in total mix, s^-1 cancel, dimensional analysis on handwritten workings
partial_pressure = cond_P*partial_water;

sat_t = 128;    %%approx saturation temp of water at the given partial pressure (Taken from tables)

%%%@100 degrees celsius, water will begin to condense, from then on it will gradually condense changing the saturation temp with time due to changing percentage water in air,...

%%Assumption is made to simplify the system here based on IE design
%%Condensed water and gas leave at a common temp below 100 degrees celsuis equal to cond_T above.
%%the remaining gas is saturated, (so that we can get a pressure for the gas at assumed temp from the tables)

P_sat = 47.58;       %%saturation pressure of the uncondensed, (assumed)-saturated gas. (interpolated from tables)

%%apply partial pressure law again
partial_sat = P_sat/cond_P;

%%from rough work in copy
m_dot_w_exh = (((air_exit/molar_air)*(partial_sat))/((1/molar_water)-(partial_sat/molar_water)));   %%DAltons law again, to find mass flow of exhauseted water
m_dot_cond = (inject_dot + H2o_dot) - m_dot_w_exh;          %%condensed water must be total water less exhausted water

fprintf("***************Evaporative Cooled System*******************\n\n")
fprintf("The rate of water recovery is %.4f kg/s\n", m_dot_cond);
fprintf("This satisifes the required cell injection rate of %.4f kg/s calculated above\n\n", inject_dot);

%%%Compressor Power Caluculations

%isentropic process
gamma = 1.33;     %%gamma of steam from tables is assumed
C_p = 1.8723;     %%spec. heat of steam from tables is assumed
Comp_eff = 0.85;    %%compressor efficiency of 85% assumed
T_2s = (273.15+T_oper)*(cond_P/P_ISA)^((gamma-1)/gamma);

q_dot = (vap_exit+dry_air)*(C_p)*(T_2s-(T_oper+273.15));                          %%isentropic power reqd
q_dot_actual = q_dot/(Comp_eff);                                                  %%actual input power reqd
T_2 = (q_dot_actual+(vap_exit+dry_air)*(T_oper)*C_p)/((vap_exit+dry_air)*C_p);    %%compressor outlet air temp

fprintf("An 85%% efficient compressor requires %.4f W to supply the condensor as required\n\n", q_dot_actual);

%%HEAT Exchanger sizing

Q_dot_air =




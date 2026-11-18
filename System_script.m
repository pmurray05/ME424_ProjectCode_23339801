clc;
close all;
clear all;

P_max = 1491;
motor_eff = 0.9;
P_req = P_max/motor_eff;
P_FC = P_req;

%%from (Doimin et al (2025)) in agreement with book ISBN: 9781420044317
FC_eff = 0.444
P_react = P_FC/FC_eff;


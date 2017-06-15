QoE-oriented Cloud Service Orchestration  v1.0 README
Updated June 14, 2017 by Dmitrii Chemodanov

All feedback appreciated to dycbt4@mail.missouri.edu 

@copyright 2017 VIMAN laboratory, Computer Science Department, University of Missouri-Columbia.
=================
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

What is inside?
================
The source code for the ACM TOMM submission (SI on QoE Management for Multimedia Services) 
titled: "On QoE-oriented Cloud Service Orchestration for Application Providers"

Matlab simulation is used to evalute the Application Service Provider (ASP) mangement plane optimization solutions
NS-3 simulation is used to evalute the ASP data plane optimization solutions

DISTRIBUTION
================
The distribution tree contains: 

* README

	** this file
    
* matlab_sim/ (source files for the ASP management plane optimization problem)	

    ** maim_tomm.m       (main file for the clustering-based ASP optimization solution)
    
    ** main_tomm_opt.m   (main file for the integer linear programming based ASP optimization solution)
    
    
* ns3_sim/ (source files for the ASP data plane optimization problem)

    ** BRITE/   (source files for the Brite topology generator that is used to generate realistic Internet topologies)
    
    ** ns-3.25/ (source files for the ASP data plane optimization evaluation)
    
        ** .m       (matlab source files from the ASP mangement optimization, that are used for service deployment)
        
        ** scratch/ (c++ source files for the ASP data plane simulation and optimization)
        
            *** lcd_simulation_ns3.cc (main file for the ASP data plane simulation and optimization)